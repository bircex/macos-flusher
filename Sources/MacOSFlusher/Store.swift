import Foundation
import Combine

enum ItemState: Equatable, Sendable {
    case unknown
    case unavailable
    case scanning
    case measured(Int64)
}

enum LogLevel: Sendable {
    case info
    case error
}

struct LogEntry: Identifiable, Sendable {
    let id: Int
    let date: Date
    let level: LogLevel
    let message: String
}

@MainActor
final class Store: ObservableObject {
    @Published private(set) var states: [String: ItemState] = [:]
    @Published var selected: Set<String> = Set(Targets.allItems.filter(\.defaultOn).map(\.id))
    @Published private(set) var busy = false
    @Published private(set) var log: [LogEntry] = []
    @Published private(set) var lastFreed: Int64?
    @Published var hideEmpty = true
    @Published private(set) var progress: Progress?
    @Published private(set) var disk: DiskInfo?
    @Published var expanded: Set<String> = Set(Targets.groups.map(\.id))
    @Published private(set) var pathSizes: [String: [String: Int64]] = [:]
    @Published private(set) var locations: [DiskLocation] = []
    @Published private(set) var analysis: Progress?

    private var current: Task<Void, Never>?
    private var logSequence = 0
    private let concurrency = 4

    init() {
        Shell.warmUp()
    }

    func size(of item: Target) -> Int64? {
        if case .measured(let bytes) = states[item.id] { return bytes }
        return nil
    }

    func isAvailable(_ item: Target) -> Bool {
        states[item.id] != .unavailable
    }

    func isVisible(_ item: Target) -> Bool {
        guard hideEmpty else { return true }
        switch states[item.id] ?? .unknown {
        case .unavailable: return false
        case .measured(let bytes): return bytes > 0
        default: return true
        }
    }

    var selectedTotal: Int64 {
        Targets.allItems.filter { selected.contains($0.id) }.compactMap(size(of:)).reduce(0, +)
    }

    var flushTargets: [Target] {
        Targets.allItems.filter { selected.contains($0.id) && isAvailable($0) }
    }

    var selectedCount: Int {
        flushTargets.count
    }

    var measuredTotal: Int64 {
        Targets.allItems.compactMap(size(of:)).reduce(0, +)
    }

    func total(of group: TargetGroup) -> Int64 {
        group.items.compactMap(size(of:)).reduce(0, +)
    }

    func selectedTotal(of group: TargetGroup) -> Int64 {
        group.items.filter { selected.contains($0.id) }.compactMap(size(of:)).reduce(0, +)
    }

    func setGroup(_ group: TargetGroup, on: Bool) {
        for item in group.items where isAvailable(item) {
            if on { selected.insert(item.id) } else { selected.remove(item.id) }
        }
    }

    func toggle(_ item: Target, on: Bool) {
        if on { selected.insert(item.id) } else { selected.remove(item.id) }
    }

    var expectedFreeAfterFlush: Int64? {
        disk.map { $0.free + selectedTotal }
    }

    var idle: Bool {
        !busy && analysis == nil
    }

    func refreshDisk() {
        disk = DiskInfo.current()
    }

    func stop() {
        current?.cancel()
    }

    func scan() {
        guard !busy else { return }
        busy = true
        lastFreed = nil
        append("Scanning…")
        current?.cancel()
        current = Task { [weak self] in
            await self?.runScan()
            self?.busy = false
            await self?.runAnalysis()
        }
    }

    func flush() {
        guard !busy else { return }
        busy = true
        lastFreed = nil
        current?.cancel()
        current = Task { [weak self] in
            await self?.runFlush()
            self?.busy = false
            await self?.runAnalysis()
        }
    }

    private func apply(_ measurement: Measurement, to id: String) {
        states[id] = measurement.state
        pathSizes[id] = measurement.paths
    }

    private func runScan() async {
        refreshDisk()
        await measure(Targets.allItems)
        refreshDisk()
        append(Task.isCancelled ? "Scan stopped." : "Scan finished.")
    }

    func measure(_ items: [Target]) async {
        progress = Progress(done: 0, total: items.count)
        for item in items { states[item.id] = .scanning }
        await withTaskGroup(of: (String, Measurement).self) { group in
            var pending = items.makeIterator()
            func enqueue() {
                guard let item = pending.next() else { return }
                group.addTask { (item.id, await Measurer.measure(item)) }
            }
            for _ in 0..<concurrency { enqueue() }
            for await (id, measurement) in group {
                apply(measurement, to: id)
                if measurement.state == .unavailable { selected.remove(id) }
                progress = Progress(done: min((progress?.done ?? 0) + 1, items.count), total: items.count)
                if Task.isCancelled {
                    group.cancelAll()
                } else {
                    enqueue()
                }
            }
        }
        for item in items where states[item.id] == .scanning { states[item.id] = .unknown }
        progress = nil
    }

    private func runFlush() async {
        lastFreed = await clean(flushTargets).freed
        append("Freed \(Format.bytes(lastFreed ?? 0)).")
    }

    func clean(_ items: [Target]) async -> [ItemResult] {
        await clean(items, until: { _ in false })
    }

    func clean(_ items: [Target], until reached: ([ItemResult]) -> Bool) async -> [ItemResult] {
        var results: [ItemResult] = []
        progress = Progress(done: 0, total: items.count)
        for (index, item) in items.enumerated() {
            let before = size(of: item) ?? 0
            if Task.isCancelled || reached(results) {
                results.append(ItemResult(id: item.id, name: item.name, before: before, after: before, status: .skipped, message: ""))
                continue
            }
            progress = Progress(done: index, total: items.count)
            states[item.id] = .scanning
            let outcome: (status: Int32, output: String)
            switch item.flush {
            case .removePaths:
                outcome = await Shell.removePaths(item.paths)
            case .command(let command):
                outcome = await Shell.command(command)
            }
            let measurement = await Measurer.measure(item)
            apply(measurement, to: item.id)
            let message = outcome.output.trimmingCharacters(in: .whitespacesAndNewlines)
            if outcome.status == 0 {
                append("Flushed \(item.name)")
            } else {
                append("\(item.name): \(message)", level: .error)
            }
            results.append(ItemResult(
                id: item.id,
                name: item.name,
                before: before,
                after: size(of: item) ?? 0,
                status: outcome.status == 0 ? .cleaned : .failed,
                message: outcome.status == 0 ? "" : message
            ))
        }
        for item in items where states[item.id] == .scanning { states[item.id] = .unknown }
        progress = nil
        refreshDisk()
        return results
    }

    private func runAnalysis() async {
        guard !Task.isCancelled else {
            analysis = nil
            return
        }
        let plan = Locations.plan()
        let roots = plan.flatMap(\.roots)
        var raw: [String: Int64] = [:]
        analysis = Progress(done: 0, total: roots.count)
        await withTaskGroup(of: (String, Int64?).self) { group in
            var pending = roots.makeIterator()
            func enqueue() {
                guard let root = pending.next() else { return }
                group.addTask { (root, await Shell.sizesOfPaths([root])[root]) }
            }
            for _ in 0..<concurrency { enqueue() }
            for await (root, bytes) in group {
                raw[root] = bytes
                if Task.isCancelled {
                    group.cancelAll()
                } else {
                    analysis = Progress(done: raw.count, total: roots.count)
                    enqueue()
                }
            }
        }
        guard !Task.isCancelled else { return }
        let targets = targetBytes(in: plan)
        locations = plan.map { location in
            var measured = location
            let bytes = location.roots.map { Locations.exclusive($0, raw: raw) }.reduce(0, +)
            measured.other = max(0, bytes - (targets[location.id]?.total ?? 0))
            return measured
        }
        analysis = nil
        refreshDisk()
        append("Disk analysis finished.")
    }

    private func append(_ message: String, level: LogLevel = .info) {
        logSequence += 1
        log.append(LogEntry(id: logSequence, date: Date(), level: level, message: message))
        if log.count > 300 { log.removeFirst(log.count - 300) }
    }
}

struct Progress: Equatable {
    let done: Int
    let total: Int

    var fraction: Double { total > 0 ? Double(done) / Double(total) : 0 }
}

struct DiskInfo: Equatable {
    let total: Int64
    let free: Int64

    var used: Int64 { total - free }
    var usedFraction: Double { total > 0 ? Double(used) / Double(total) : 0 }

    static func current() -> DiskInfo? {
        let url = URL(fileURLWithPath: "/")
        guard let values = try? url.resourceValues(forKeys: [.volumeTotalCapacityKey, .volumeAvailableCapacityForImportantUsageKey]),
              let total = values.volumeTotalCapacity,
              let free = values.volumeAvailableCapacityForImportantUsage else { return nil }
        return DiskInfo(total: Int64(total), free: free)
    }
}

struct Measurement: Sendable {
    let state: ItemState
    var paths: [String: Int64] = [:]
}

struct ItemResult: Equatable, Sendable {
    enum Status: Sendable {
        case cleaned
        case failed
        case skipped
    }

    let id: String
    let name: String
    let before: Int64
    let after: Int64
    let status: Status
    let message: String
}

extension Array where Element == ItemResult {
    var freed: Int64 {
        Swift.max(0, map(\.before).reduce(0, +) - map(\.after).reduce(0, +))
    }
}

enum Measurer {
    static func measure(_ item: Target) async -> Measurement {
        if let binary = item.requires, !Shell.exists(binary: binary) {
            return Measurement(state: .unavailable)
        }
        if let command = item.sizeCommand {
            return Measurement(state: .measured(Shell.parseSizes(await Shell.command(command).output)))
        }
        let paths = await Shell.sizesOfPaths(item.paths)
        return Measurement(state: .measured(paths.values.reduce(0, +)), paths: paths)
    }
}

enum Format {
    private static let formatter: ByteCountFormatter = {
        let f = ByteCountFormatter()
        f.countStyle = .file
        return f
    }()

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f
    }()

    static func bytes(_ value: Int64) -> String {
        formatter.string(fromByteCount: value)
    }

    static func percent(_ fraction: Double) -> String {
        "\(Int((fraction * 100).rounded()))%"
    }

    static func time(_ date: Date) -> String {
        timeFormatter.string(from: date)
    }
}

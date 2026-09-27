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
    @Published var selected: Set<String> = Set(Catalog.allItems.filter(\.defaultOn).map(\.id))
    @Published private(set) var busy = false
    @Published private(set) var log: [LogEntry] = []
    @Published private(set) var lastFreed: Int64?
    @Published var hideEmpty = true
    @Published private(set) var progress: Progress?
    @Published private(set) var disk: DiskInfo?
    @Published var expanded: Set<String> = Set(Catalog.groups.map(\.id))

    private var current: Task<Void, Never>?
    private var logSequence = 0
    private let concurrency = 4

    init() {
        Shell.warmUp()
    }

    func size(of item: CacheItem) -> Int64? {
        if case .measured(let bytes) = states[item.id] { return bytes }
        return nil
    }

    func isAvailable(_ item: CacheItem) -> Bool {
        states[item.id] != .unavailable
    }

    func isVisible(_ item: CacheItem) -> Bool {
        guard hideEmpty else { return true }
        switch states[item.id] ?? .unknown {
        case .unavailable: return false
        case .measured(let bytes): return bytes > 0
        default: return true
        }
    }

    var selectedTotal: Int64 {
        Catalog.allItems.filter { selected.contains($0.id) }.compactMap(size(of:)).reduce(0, +)
    }

    var selectedCount: Int {
        Catalog.allItems.filter { selected.contains($0.id) && isAvailable($0) }.count
    }

    var measuredTotal: Int64 {
        Catalog.allItems.compactMap(size(of:)).reduce(0, +)
    }

    func total(of group: CacheGroup) -> Int64 {
        group.items.compactMap(size(of:)).reduce(0, +)
    }

    func selectedTotal(of group: CacheGroup) -> Int64 {
        group.items.filter { selected.contains($0.id) }.compactMap(size(of:)).reduce(0, +)
    }

    func setGroup(_ group: CacheGroup, on: Bool) {
        for item in group.items where isAvailable(item) {
            if on { selected.insert(item.id) } else { selected.remove(item.id) }
        }
    }

    func toggle(_ item: CacheItem, on: Bool) {
        if on { selected.insert(item.id) } else { selected.remove(item.id) }
    }

    var expectedFreeAfterFlush: Int64? {
        disk.map { $0.free + selectedTotal }
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
        current = Task { [weak self] in
            await self?.runScan()
            self?.busy = false
        }
    }

    func flush() {
        guard !busy else { return }
        busy = true
        lastFreed = nil
        current = Task { [weak self] in
            await self?.runFlush()
            self?.busy = false
        }
    }

    private func runScan() async {
        let items = Catalog.allItems
        refreshDisk()
        progress = Progress(done: 0, total: items.count)
        for item in items { states[item.id] = .scanning }
        await withTaskGroup(of: (String, ItemState).self) { group in
            var pending = items.makeIterator()
            func enqueue() {
                guard let item = pending.next() else { return }
                group.addTask { (item.id, await Measurer.measure(item)) }
            }
            for _ in 0..<concurrency { enqueue() }
            for await (id, state) in group {
                states[id] = state
                if state == .unavailable { selected.remove(id) }
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
        refreshDisk()
        append(Task.isCancelled ? "Scan stopped." : "Scan finished.")
    }

    private func runFlush() async {
        let items = Catalog.allItems.filter { selected.contains($0.id) && isAvailable($0) }
        let before = items.compactMap(size(of:)).reduce(0, +)
        var after: Int64 = 0
        progress = Progress(done: 0, total: items.count)
        for (index, item) in items.enumerated() {
            if Task.isCancelled { break }
            progress = Progress(done: index, total: items.count)
            states[item.id] = .scanning
            let result: (status: Int32, output: String)
            switch item.flush {
            case .removePaths:
                result = await Shell.removePaths(item.paths)
            case .command(let command):
                result = await Shell.command(command)
            }
            let state = await Measurer.measure(item)
            states[item.id] = state
            if case .measured(let bytes) = state { after += bytes }
            if result.status == 0 {
                append("Flushed \(item.name)")
            } else {
                append("\(item.name): \(result.output.trimmingCharacters(in: .whitespacesAndNewlines))", level: .error)
            }
        }
        for item in items where states[item.id] == .scanning { states[item.id] = .unknown }
        progress = nil
        refreshDisk()
        lastFreed = max(0, before - after)
        append("Freed \(Format.bytes(lastFreed ?? 0)).")
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

enum Measurer {
    static func measure(_ item: CacheItem) async -> ItemState {
        if let binary = item.requires, !Shell.exists(binary: binary) {
            return .unavailable
        }
        if let command = item.sizeCommand {
            return .measured(Shell.parseSizes(await Shell.command(command).output))
        }
        if item.paths.isEmpty {
            return .measured(0)
        }
        return .measured(await Shell.sizeOfPaths(item.paths))
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

import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct Theme: Identifiable {
    typealias Pair = (light: Int, dark: Int)

    let id: String
    let name: String
    let blue: Pair
    let green: Pair
    let yellow: Pair
    let red: Pair

    static let key = "theme"

    static let code2026 = Theme(
        id: "code-2026",
        name: "Code 2026",
        blue: (light: 0x1A5CFF, dark: 0x57A3F8),
        green: (light: 0x388A34, dark: 0x86CF86),
        yellow: (light: 0x667309, dark: 0xE0B97F),
        red: (light: 0xAD0707, dark: 0xEF8773)
    )

    static let all = [code2026]

    var swatches: [Color] { [Palette.dynamic(blue), Palette.dynamic(green), Palette.dynamic(yellow), Palette.dynamic(red)] }

    static var stored: Theme {
        theme(id: UserDefaults.standard.string(forKey: key) ?? "")
    }

    static func theme(id: String) -> Theme {
        all.first { $0.id == id } ?? code2026
    }
}

enum Palette {
    static var otherData: Color { dynamic(Theme.stored.blue) }
    static var selected: Color { dynamic(Theme.stored.green) }
    static var unselected: Color { dynamic(Theme.stored.yellow) }
    static var warning: Color { dynamic(Theme.stored.red) }
    static let free = Color.secondary.opacity(0.25)

    static func dynamic(_ pair: Theme.Pair) -> Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            let hex = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? pair.dark : pair.light
            return NSColor(
                srgbRed: CGFloat((hex >> 16) & 0xff) / 255,
                green: CGFloat((hex >> 8) & 0xff) / 255,
                blue: CGFloat(hex & 0xff) / 255,
                alpha: 1
            )
        })
    }
}

struct Series: Identifiable {
    let name: String
    let color: Color
    var bytes: Int64 = 0

    var id: String { name }

    static func otherData(_ bytes: Int64 = 0) -> Series { Series(name: Messages.otherData, color: Palette.otherData, bytes: bytes) }
    static func unselected(_ bytes: Int64 = 0) -> Series { Series(name: Messages.unselected, color: Palette.unselected, bytes: bytes) }
    static func selected(_ bytes: Int64 = 0) -> Series { Series(name: Messages.selected, color: Palette.selected, bytes: bytes) }
}

struct DiskSlice: Identifiable {
    let id: String
    let name: String
    let bytes: Int64
    let color: Color
}

extension Store {
    var diskSlices: [DiskSlice] {
        guard let disk else { return [] }
        let chosen = min(selectedTotal, disk.used)
        let kept = min(max(0, measuredTotal - selectedTotal), disk.used - chosen)
        return [
            DiskSlice(id: "other", name: Messages.otherData, bytes: disk.used - chosen - kept, color: Palette.otherData),
            DiskSlice(id: "unselected", name: Messages.unselectedTargets, bytes: kept, color: Palette.unselected),
            DiskSlice(id: "selected", name: Messages.selectedTargets, bytes: chosen, color: Palette.selected),
            DiskSlice(id: "free", name: Messages.free, bytes: disk.free, color: Palette.free),
        ]
    }
}

struct DiskDonut: View {
    @EnvironmentObject var store: Store
    private let lineWidth: CGFloat = 16
    private let gap = 0.005
    private let minimumSweep = 0.004

    var body: some View {
        let slices = store.diskSlices
        let total = Double(max(slices.map(\.bytes).reduce(0, +), 1))
        ZStack {
            ForEach(Array(slices.enumerated()), id: \.element.id) { index, slice in
                let start = Double(slices.prefix(index).map(\.bytes).reduce(0, +)) / total
                let end = start + Double(slice.bytes) / total
                if slice.bytes > 0 {
                    Circle()
                        .trim(from: start + gap / 2, to: max(end - gap / 2, start + gap / 2 + minimumSweep))
                        .stroke(slice.color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .butt))
                        .rotationEffect(.degrees(-90))
                }
            }
            VStack(spacing: 0) {
                Text(Format.percent(store.disk?.usedFraction ?? 0))
                    .font(.system(size: 24, weight: .semibold))
                Text(Messages.used)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(lineWidth / 2)
        .frame(width: 124, height: 124)
    }
}

struct DiskLegend: View {
    @EnvironmentObject var store: Store

    var body: some View {
        let total = Double(max(store.disk?.total ?? 1, 1))
        HStack(spacing: 10) {
            ForEach(store.diskSlices) { slice in
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(slice.color)
                            .frame(width: 10, height: 10)
                        Text(slice.name)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Text(Format.bytes(slice.bytes))
                        .font(.system(size: 17, weight: .semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text(String(format: Messages.ofDisk, Format.percent(Double(slice.bytes) / total)))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.secondary.opacity(0.08)))
                .help("\(slice.name): \(Format.bytes(slice.bytes))")
            }
        }
    }
}

struct LocationChart: View {
    @EnvironmentObject var store: Store

    private var detail: String {
        if let analysis = store.analysis { return String(format: Messages.analyzingOf, analysis.done, analysis.total) }
        return String(format: Messages.usedAmount, Format.bytes(store.disk?.used ?? 0))
    }

    var body: some View {
        let rows = store.locationRows
        let scale = Double(max(rows.map(\.total).max() ?? 1, 1))
        ChartPanel(
            title: Messages.byLocation,
            detail: detail,
            legend: [.otherData(), .unselected(), .selected()],
            placeholder: rows.isEmpty ? (store.busy || store.analysis != nil ? Messages.analyzingDisk : Messages.notAnalyzed) : nil
        ) {
            ForEach(rows) { row in
                bar(row, scale: scale, nested: false)
                ForEach(row.children) { child in
                    bar(child, scale: scale, nested: true)
                }
            }
        }
    }

    private func bar(_ row: LocationRow, scale: Double, nested: Bool) -> some View {
        ChartRow(
            name: localized(row.name),
            series: [.otherData(row.other), .unselected(row.targets.unselected), .selected(row.targets.selected)],
            scale: scale,
            nested: nested
        )
    }
}

struct GroupChart: View {
    @EnvironmentObject var store: Store

    private var rows: [(group: TargetGroup, selected: Int64, total: Int64)] {
        store.groups
            .map { (group: $0, selected: store.selectedTotal(of: $0), total: store.total(of: $0)) }
            .filter { $0.total > 0 }
            .sorted { $0.total > $1.total }
    }

    var body: some View {
        let rows = rows
        let scale = Double(max(rows.first?.total ?? 1, 1))
        ChartPanel(
            title: Messages.byGroup,
            detail: String(format: Messages.found, Format.bytes(store.measuredTotal)),
            legend: [.unselected(), .selected()],
            placeholder: rows.isEmpty ? (store.busy ? Messages.scanning : Messages.noTargetsFound) : nil
        ) {
            ForEach(rows, id: \.group.id) { row in
                ChartRow(
                    name: localized(row.group.name),
                    series: [.unselected(row.total - row.selected), .selected(row.selected)],
                    scale: scale
                )
            }
        }
    }
}

struct ChartPanel<Content: View>: View {
    let title: String
    let detail: String
    let legend: [Series]
    let placeholder: String?
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text(title)
                        .font(.callout.weight(.semibold))
                    Spacer()
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                HStack(spacing: 12) {
                    ForEach(legend) { series in
                        HStack(spacing: 5) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(series.color)
                                .frame(width: 10, height: 10)
                            Text(series.name)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            Divider()
            if let placeholder {
                Text(placeholder)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        content
                    }
                    .padding()
                }
            }
        }
        .frame(maxHeight: .infinity)
    }
}

struct ChartRow: View {
    let name: String
    let series: [Series]
    let scale: Double
    var nested = false

    private var summary: String {
        series.filter { $0.bytes > 0 }
            .map { "\(Format.bytes($0.bytes)) \($0.name.lowercased())" }
            .joined(separator: ", ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text(name)
                    .font(.caption)
                    .foregroundStyle(nested ? HierarchicalShapeStyle.secondary : .primary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .padding(.leading, nested ? 14 : 0)
                Spacer(minLength: 8)
                Text(Format.bytes(series.map(\.bytes).reduce(0, +)))
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            StackedBar(series: series, scale: scale)
                .frame(height: nested ? 8 : 12)
        }
        .help("\(name): \(summary)")
    }
}

struct StackedBar: View {
    let series: [Series]
    let scale: Double

    var body: some View {
        GeometryReader { geo in
            let visible = series.filter { $0.bytes > 0 }
            let reserved = CGFloat(max(visible.count - 1, 0)) * 2 + CGFloat(visible.count)
            HStack(spacing: 2) {
                ForEach(visible) { segment in
                    Rectangle()
                        .fill(segment.color)
                        .frame(width: 1 + max(0, geo.size.width - reserved) * Double(segment.bytes) / scale)
                }
            }
            .clipShape(UnevenRoundedRectangle(bottomTrailingRadius: 4, topTrailingRadius: 4))
        }
    }
}

struct LargestTarget: Identifiable {
    let id: String
    let name: String
    let groupName: String
    let bytes: Int64
}

extension Store {
    var largestTargets: [LargestTarget] {
        Array(
            groups.flatMap { group in
                group.items.compactMap { item -> LargestTarget? in
                    guard let bytes = size(of: item), bytes > 0 else { return nil }
                    return LargestTarget(id: item.id, name: localized(item.name), groupName: localized(group.name), bytes: bytes)
                }
            }
            .sorted { $0.bytes > $1.bytes }
            .prefix(10)
        )
    }
}

enum CSV {
    static func text(_ header: [String], _ rows: [[String]]) -> String {
        ([header] + rows).map { $0.map(field).joined(separator: ",") }.joined(separator: "\r\n")
    }

    private static func field(_ value: String) -> String {
        guard value.contains(",") || value.contains("\"") || value.contains("\n") else { return value }
        return "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }

    static func save(_ text: String, suggestedName: String) {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = suggestedName
        panel.allowedContentTypes = [.commaSeparatedText]
        guard panel.runModal() == .OK, let url = panel.url else { return }
        try? text.write(to: url, atomically: true, encoding: .utf8)
    }
}

struct CategoryChart: View {
    @EnvironmentObject var store: Store

    private var rows: [(audience: Audience, selected: Int64, total: Int64)] {
        Audience.allCases
            .filter { $0 != .mine }
            .map { (audience: $0, selected: store.selectedTotal(of: $0), total: store.total(of: $0)) }
            .filter { $0.total > 0 }
            .sorted { $0.total > $1.total }
    }

    var body: some View {
        let rows = rows
        let scale = Double(max(rows.first?.total ?? 1, 1))
        ChartPanel(
            title: Messages.byCategory,
            detail: String(format: Messages.found, Format.bytes(store.measuredTotal)),
            legend: [.unselected(), .selected()],
            placeholder: rows.isEmpty ? (store.busy ? Messages.scanning : Messages.noTargetsFound) : nil
        ) {
            ForEach(rows, id: \.audience) { row in
                ChartRow(
                    name: row.audience.name,
                    series: [.unselected(row.total - row.selected), .selected(row.selected)],
                    scale: scale
                )
            }
        }
    }
}

struct LargestTargetsCard: View {
    @EnvironmentObject var store: Store

    var body: some View {
        let items = store.largestTargets
        VStack(alignment: .leading, spacing: 10) {
            Text(Messages.largestTargets)
                .font(.callout.weight(.semibold))
            if items.isEmpty {
                Text(Messages.notAnalyzed)
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        HStack(spacing: 10) {
                            Text("\(index + 1)")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(.secondary)
                                .frame(width: 16, alignment: .trailing)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(item.name).font(.callout)
                                Text(item.groupName).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(Format.bytes(item.bytes))
                                .font(.system(.callout, design: .monospaced))
                        }
                        if item.id != items.last?.id { Divider() }
                    }
                }
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.secondary.opacity(0.06)))
    }
}

struct ReportToolbar: ToolbarContent {
    let action: () -> Void

    var body: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button(Messages.exportCSV, action: action)
        }
    }
}

struct OverviewPage: View {
    @EnvironmentObject var store: Store

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 16) {
                    DiskDonut()
                    DiskLegend()
                }
                LargestTargetsCard()
            }
            .padding()
        }
        .toolbar { ReportToolbar(action: exportCSV) }
    }

    private func exportCSV() {
        let rows = store.largestTargets.map { [$0.name, $0.groupName, String($0.bytes)] }
        CSV.save(CSV.text(["Target", "Group", "Bytes"], rows), suggestedName: "Overview.csv")
    }
}

struct LocationsPage: View {
    @EnvironmentObject var store: Store

    var body: some View {
        LocationChart()
            .toolbar { ReportToolbar(action: exportCSV) }
    }

    private func exportCSV() {
        let rows = store.locationRows.flatMap { row -> [[String]] in
            var lines = [[row.name, String(row.other), String(row.targets.unselected), String(row.targets.selected), String(row.total)]]
            lines += row.children.map { [$0.name, String($0.other), String($0.targets.unselected), String($0.targets.selected), String($0.total)] }
            return lines
        }
        CSV.save(CSV.text(["Location", "Other data", "Unselected", "Selected", "Total"], rows), suggestedName: "Locations.csv")
    }
}

struct CategoriesPage: View {
    @EnvironmentObject var store: Store

    var body: some View {
        VStack(spacing: 0) {
            CategoryChart()
            Divider()
            GroupChart()
        }
        .toolbar { ReportToolbar(action: exportCSV) }
    }

    private func exportCSV() {
        let rows = store.groups.filter { $0.audience != .mine }.map { group in
            [group.audience.name, localized(group.name), String(store.selectedTotal(of: group)), String(store.total(of: group))]
        }
        CSV.save(CSV.text(["Category", "Group", "Selected", "Total"], rows), suggestedName: "Categories.csv")
    }
}

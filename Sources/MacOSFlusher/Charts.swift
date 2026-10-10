import SwiftUI
import AppKit

enum Palette {
    static let blue = (light: 0x1A5CFF, dark: 0x57A3F8)
    static let green = (light: 0x388A34, dark: 0x86CF86)
    static let yellow = (light: 0x667309, dark: 0xE0B97F)
    static let red = (light: 0xAD0707, dark: 0xEF8773)

    static let otherData = dynamic(blue)
    static let selected = dynamic(green)
    static let unselected = dynamic(yellow)
    static let warning = dynamic(red)
    static let free = Color.secondary.opacity(0.25)

    private static func dynamic(_ pair: (light: Int, dark: Int)) -> Color {
        dynamic(light: pair.light, dark: pair.dark)
    }

    private static func dynamic(light: Int, dark: Int) -> Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            let hex = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? dark : light
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

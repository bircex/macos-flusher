import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: Store
    @State private var confirmFlush = false

    var body: some View {
        VStack(spacing: 0) {
            header
            overview
            Divider()
            HStack(spacing: 0) {
                List {
                    ForEach(Audience.allCases) { audience in
                        AudienceSection(audience: audience)
                    }
                }
                .listStyle(.inset)
                Divider()
                VStack(spacing: 0) {
                    LocationChart()
                    Divider()
                    GroupChart()
                }
                .frame(width: 320)
            }
            Divider()
            LogView()
        }
        .frame(minWidth: 960, minHeight: 820)
        .confirmationDialog(
            "Delete \(Format.bytes(store.selectedTotal)) across \(Messages.targets(store.selectedCount))?",
            isPresented: $confirmFlush,
            titleVisibility: .visible
        ) {
            Button("Flush", role: .destructive) { store.flush() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(store.flushTargets.warning)
        }
        .onAppear { store.scan() }
    }

    private var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("MacOS Flusher").font(.title2.bold())
                Text("Selected: \(Format.bytes(store.selectedTotal)) in \(Messages.targets(store.selectedCount))")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Toggle("Hide empty", isOn: $store.hideEmpty)
                .toggleStyle(.checkbox)
            if store.busy {
                Button("Stop") { store.stop() }
            } else {
                Button("Scan") { store.scan() }
            }
            Button("Flush selected") { confirmFlush = true }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .disabled(store.busy || store.selectedCount == 0)
        }
        .padding()
    }

    private var overview: some View {
        HStack(spacing: 16) {
            DiskDonut()
            VStack(spacing: 10) {
                DiskLegend()
                DiskBar()
                progressBar
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 12)
    }

    private var progressBar: some View {
        let fraction = store.progress?.fraction ?? 0
        return PercentBar(fraction: fraction, tint: .accentColor, label: Format.percent(fraction))
            .opacity(store.progress == nil ? 0 : 1)
    }
}

struct PercentBar: View {
    let fraction: Double
    var behind: Double?
    let tint: Color
    let label: String

    var body: some View {
        HStack(spacing: 10) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6).fill(Color.secondary.opacity(0.2))
                    if let behind {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Palette.selected)
                            .frame(width: geo.size.width * min(max(behind, 0), 1))
                    }
                    RoundedRectangle(cornerRadius: 6)
                        .fill(tint)
                        .frame(width: geo.size.width * min(max(fraction, 0), 1))
                }
            }
            .frame(height: 18)
            Text(label)
                .font(.system(.callout, design: .monospaced).weight(.semibold))
                .frame(width: 100, alignment: .trailing)
        }
    }
}

struct DiskBar: View {
    @EnvironmentObject var store: Store

    var body: some View {
        if let disk = store.disk {
            let expectedFraction = max(0, disk.usedFraction - Double(store.selectedTotal) / Double(max(disk.total, 1)))
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Disk usage")
                        .font(.callout.weight(.medium))
                    Spacer()
                    Text("\(Format.bytes(disk.free)) free of \(Format.bytes(disk.total))")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    if let expected = store.expectedFreeAfterFlush, store.selectedTotal > 0 {
                        Text("→ \(Format.bytes(expected)) after flush")
                            .font(.callout.weight(.medium))
                            .foregroundStyle(.green)
                    }
                    if let freed = store.lastFreed {
                        Text("Freed \(Format.bytes(freed))")
                            .font(.callout.weight(.medium))
                            .foregroundStyle(.green)
                    }
                }
                PercentBar(
                    fraction: expectedFraction,
                    behind: disk.usedFraction,
                    tint: disk.usedFraction > 0.9 ? Color.red : Color.accentColor,
                    label: store.selectedTotal > 0
                        ? "\(Format.percent(disk.usedFraction)) → \(Format.percent(expectedFraction))"
                        : Format.percent(disk.usedFraction)
                )
            }
        }
    }
}

struct AudienceSection: View {
    @EnvironmentObject var store: Store
    let audience: Audience

    private var groups: [TargetGroup] {
        Targets.groups.filter { $0.audience == audience && $0.items.contains(where: store.isVisible) }
    }

    var body: some View {
        if !groups.isEmpty {
            Section(audience.name) {
                ForEach(groups) { group in
                    GroupSection(group: group)
                }
            }
        }
    }
}

struct GroupSection: View {
    @EnvironmentObject var store: Store
    let group: TargetGroup

    private var visibleItems: [Target] {
        group.items.filter(store.isVisible)
    }

    private var isExpanded: Binding<Bool> {
        Binding(
            get: { store.expanded.contains(group.id) },
            set: { on in
                if on { store.expanded.insert(group.id) } else { store.expanded.remove(group.id) }
            }
        )
    }

    var body: some View {
        if !visibleItems.isEmpty {
            DisclosureGroup(isExpanded: isExpanded) {
                ForEach(visibleItems) { item in
                    ItemRow(item: item)
                }
            } label: {
                HStack {
                    Text(group.name).font(.headline)
                    Spacer()
                    Text(Format.bytes(store.total(of: group)))
                        .font(.system(.callout, design: .monospaced))
                        .foregroundStyle(.secondary)
                    Button("All") { store.setGroup(group, on: true) }
                    Button("None") { store.setGroup(group, on: false) }
                }
                .buttonStyle(.link)
                .font(.caption)
                .padding(.vertical, 4)
            }
        }
    }
}

struct ItemRow: View {
    @EnvironmentObject var store: Store
    let item: Target

    private var isOn: Binding<Bool> {
        Binding(
            get: { store.selected.contains(item.id) },
            set: { store.toggle(item, on: $0) }
        )
    }

    var body: some View {
        HStack {
            Toggle(isOn: isOn) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(item.name)
                        if let label = item.risk.label {
                            Text(label)
                                .font(.caption)
                                .fontWeight(item.risk == .data ? .semibold : .regular)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Text(item.detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
            .toggleStyle(.checkbox)
            .disabled(!store.isAvailable(item))
            Spacer()
            sizeLabel
        }
        .padding(.vertical, 2)
        .opacity(store.isAvailable(item) ? 1 : 0.5)
    }

    @ViewBuilder
    private var sizeLabel: some View {
        switch store.states[item.id] ?? .unknown {
        case .unknown:
            Text("–").foregroundStyle(.secondary)
        case .unavailable:
            Text("not installed").font(.caption).foregroundStyle(.secondary)
        case .scanning:
            ProgressView().controlSize(.mini)
        case .measured(let bytes):
            Text(bytes == 0 ? "empty" : Format.bytes(bytes))
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(bytes == 0 ? .secondary : .primary)
        }
    }
}

extension LogLevel {
    var label: String {
        switch self {
        case .info: return "INFO"
        case .error: return "ERROR"
        }
    }

    var icon: String {
        switch self {
        case .info: return "info.circle.fill"
        case .error: return "exclamationmark.triangle.fill"
        }
    }

    var color: Color {
        switch self {
        case .info: return .blue
        case .error: return .red
        }
    }
}

struct LogRow: View {
    let entry: LogEntry

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Image(systemName: entry.level.icon)
                .foregroundStyle(entry.level.color)
                .frame(width: 14)
            Text(Format.time(entry.date))
                .foregroundStyle(.secondary)
            Text(entry.level.label)
                .fontWeight(.semibold)
                .foregroundStyle(entry.level.color)
                .frame(width: 40, alignment: .leading)
            Text(entry.message)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .font(.system(.caption, design: .monospaced))
        .padding(.horizontal)
        .padding(.vertical, 3)
        .background(entry.level == .error ? Color.red.opacity(0.1) : Color.clear)
    }
}

struct LogView: View {
    @EnvironmentObject var store: Store

    private func count(_ level: LogLevel) -> Int {
        store.log.filter { $0.level == level }.count
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Text("Activity log")
                    .font(.callout.weight(.semibold))
                Spacer()
                ForEach([LogLevel.info, .error], id: \.self) { level in
                    Label("\(count(level))", systemImage: level.icon)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(level.color)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 6)
            Divider()
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(store.log) { entry in
                            LogRow(entry: entry).id(entry.id)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .frame(height: 130)
                .onChange(of: store.log.last?.id) { id in
                    if let id { proxy.scrollTo(id, anchor: .bottom) }
                }
            }
        }
    }
}

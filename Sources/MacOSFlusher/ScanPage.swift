import SwiftUI

struct ScanRow: Identifiable {
    let id: String
    let target: Target
    let name: String
    let category: Audience
    let categoryName: String
    let groupName: String
    let bytes: Int64
    let state: ItemState
    let custom: Bool
    let risk: Risk
}

extension Store {
    var scanRows: [ScanRow] {
        groups.flatMap { group in
            group.items.filter(isVisible).map { item in
                ScanRow(
                    id: item.id,
                    target: item,
                    name: item.name,
                    category: group.audience,
                    categoryName: group.audience.name,
                    groupName: localized(group.name),
                    bytes: size(of: item) ?? 0,
                    state: states[item.id] ?? .unknown,
                    custom: item.custom,
                    risk: item.risk
                )
            }
        }
    }
}

struct ScanPage: View {
    @EnvironmentObject var store: Store
    @State private var filter: Audience?
    @State private var sortOrder = [KeyPathComparator(\ScanRow.name)]

    private var rows: [ScanRow] {
        store.scanRows.filter { filter == nil || $0.category == filter }
    }

    private var sortedRows: [ScanRow] {
        rows.sorted(using: sortOrder)
    }

    var body: some View {
        VStack(spacing: 0) {
            ScanProgressPanel()
            CategoryChips(filter: $filter)
                .padding(.horizontal)
                .padding(.top, 4)
                .padding(.bottom, 10)
            FlushActionBar()
            Divider()
            HStack {
                Text(Messages.findings)
                    .font(.callout.weight(.semibold))
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            if sortedRows.isEmpty {
                emptyState
            } else {
                table
            }
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: 12) {
            Text(filter == .mine ? Messages.noOwnTargets : Messages.nothingHere)
                .foregroundStyle(.secondary)
            if filter == .mine {
                Button(Messages.addTarget) { store.edited = UserTarget() }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var table: some View {
        Table(sortedRows, sortOrder: $sortOrder) {
            TableColumn("") { row in
                Toggle(
                    "",
                    isOn: Binding(
                        get: { store.selected.contains(row.id) },
                        set: { store.toggle(row.target, on: $0) }
                    )
                )
                .toggleStyle(.checkbox)
                .labelsHidden()
                .disabled(!store.isAvailable(row.target))
            }
            .width(26)

            TableColumn(Messages.editorName, value: \.name) { row in
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(row.name)
                        if let label = row.risk.label {
                            Text(label)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Text(row.target.detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                .opacity(store.isAvailable(row.target) ? 1 : 0.5)
            }
            .width(min: 220, ideal: 320)

            TableColumn(Messages.category, value: \.categoryName)
            TableColumn(Messages.group, value: \.groupName)

            TableColumn("") { row in
                if row.custom {
                    Button {
                        store.edited = store.userTargets.first { $0.id == row.id }
                    } label: {
                        Image(systemName: "pencil")
                    }
                    .buttonStyle(.plain)
                }
            }
            .width(22)

            TableColumn(Messages.size, value: \.bytes) { row in
                sizeCell(row.state)
            }
            .width(90)
        }
    }

    @ViewBuilder
    private func sizeCell(_ state: ItemState) -> some View {
        switch state {
        case .unknown:
            Text("–").foregroundStyle(.secondary)
        case .unavailable:
            Text(Messages.notInstalled).font(.caption).foregroundStyle(.secondary)
        case .scanning:
            ProgressView().controlSize(.mini)
        case .measured(let bytes):
            Text(bytes == 0 ? Messages.empty : Format.bytes(bytes))
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(bytes == 0 ? .secondary : .primary)
        }
    }
}

struct CategoryChips: View {
    @EnvironmentObject var store: Store
    @Binding var filter: Audience?

    private var present: [Audience] {
        Audience.allCases.filter { audience in store.groups.contains { $0.audience == audience } }
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip(Messages.all, isOn: filter == nil) { filter = nil }
                ForEach(present) { audience in
                    chip(audience.name, isOn: filter == audience) { filter = audience }
                }
            }
        }
    }

    private func chip(_ title: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.callout)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Capsule().fill(isOn ? Color.accentColor : Color.secondary.opacity(0.12)))
                .foregroundStyle(isOn ? Color.white : Color.primary)
        }
        .buttonStyle(.plain)
    }
}

struct ScanProgressPanel: View {
    @EnvironmentObject var store: Store

    private var statusText: String {
        if store.busy { return Messages.scanning }
        if store.progress == nil && store.measuredTotal == 0 { return Messages.notAnalyzed }
        return Messages.scanFinished
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(statusText).font(.callout.weight(.semibold))
                Spacer()
                if let progress = store.progress {
                    Text(String(format: Messages.progressOf, progress.done, progress.total))
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
            }
            HStack(spacing: 10) {
                statTile(Messages.scanned, "\(store.allItems.filter { store.states[$0.id] != nil && store.states[$0.id] != .unknown }.count) / \(store.allItems.count)")
                statTile(Messages.selectedTargets, Format.bytes(store.selectedTotal))
                if let disk = store.disk {
                    statTile(Messages.free, Format.bytes(disk.free))
                }
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.secondary.opacity(0.06)))
        .padding([.horizontal, .top])
    }

    private func statTile(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(.title3, design: .monospaced).weight(.semibold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.secondary.opacity(0.06)))
    }
}

struct FlushActionBar: View {
    @EnvironmentObject var store: Store

    var body: some View {
        if store.selectedCount > 0 {
            HStack {
                Text(String(format: Messages.selectedIn, Format.bytes(store.selectedTotal), Messages.targets(store.selectedCount), Format.bytes(store.expectedFreeAfterFlush ?? 0)))
                    .font(.callout.weight(.medium))
                Spacer()
                Button(Messages.flushMenu) { store.confirmFlush = true }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .disabled(store.busy)
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(Palette.selected.opacity(0.12))
        }
    }
}

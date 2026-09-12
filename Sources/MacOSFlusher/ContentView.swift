import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: Store
    @State private var confirmFlush = false

    var body: some View {
        VStack(spacing: 0) {
            header
            DiskBar()
            progressBar
            Divider()
            List {
                ForEach(Catalog.groups) { group in
                    GroupSection(group: group)
                }
            }
            .listStyle(.inset)
            Divider()
            LogView()
        }
        .frame(minWidth: 760, minHeight: 640)
        .confirmationDialog(
            "Delete \(Format.bytes(store.selectedTotal)) across \(store.selectedCount) categories?",
            isPresented: $confirmFlush,
            titleVisibility: .visible
        ) {
            Button("Flush", role: .destructive) { store.flush() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Caches are rebuilt on demand. Named Docker volumes and project files are never touched.")
        }
        .onAppear { store.scan() }
    }

    private var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("MacOS Flusher").font(.title2.bold())
                Text("Selected: \(Format.bytes(store.selectedTotal)) in \(store.selectedCount) categories")
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

    @ViewBuilder
    private var progressBar: some View {
        if let progress = store.progress {
            ProgressView(value: progress.fraction)
                .progressViewStyle(.linear)
                .padding(.horizontal)
                .padding(.bottom, 8)
        } else {
            Color.clear.frame(height: 14)
        }
    }
}

struct DiskBar: View {
    @EnvironmentObject var store: Store

    var body: some View {
        if let disk = store.disk {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Disk \(Int(disk.usedFraction * 100))% full")
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
                GeometryReader { geo in
                    let expectedFraction = max(0, disk.usedFraction - Double(store.selectedTotal) / Double(max(disk.total, 1)))
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4).fill(Color.secondary.opacity(0.2))
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.orange.opacity(0.5))
                            .frame(width: geo.size.width * disk.usedFraction)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(disk.usedFraction > 0.9 ? Color.red : Color.accentColor)
                            .frame(width: geo.size.width * expectedFraction)
                    }
                }
                .frame(height: 10)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
    }
}

struct GroupSection: View {
    @EnvironmentObject var store: Store
    let group: CacheGroup

    private var visibleItems: [CacheItem] {
        group.items.filter(store.isVisible)
    }

    private var groupTotal: Int64 {
        group.items.compactMap(store.size(of:)).reduce(0, +)
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
                    Text(Format.bytes(groupTotal))
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
    let item: CacheItem

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
                    Text(item.name)
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

struct LogView: View {
    @EnvironmentObject var store: Store

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(Array(store.log.enumerated()), id: \.offset) { index, line in
                        Text(line)
                            .font(.system(.caption, design: .monospaced))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .id(index)
                    }
                }
                .padding(8)
            }
            .frame(height: 110)
            .onChange(of: store.log.count) { count in
                proxy.scrollTo(count - 1, anchor: .bottom)
            }
        }
    }
}

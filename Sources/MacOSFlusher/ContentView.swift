import SwiftUI

enum Page: Hashable {
    case home
    case all
    case audience(Audience)
    case charts
    case activity
    case settings
    case about

    var title: String {
        switch self {
        case .home: return Messages.home
        case .all: return Messages.all
        case .audience(let audience): return audience.name
        case .charts: return Messages.charts
        case .activity: return Messages.activity
        case .settings: return Messages.settings
        case .about: return Messages.about
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var store: Store

    var body: some View {
        NavigationSplitView {
            Sidebar()
                .navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 320)
        } detail: {
            VStack(spacing: 0) {
                DiskLine()
                Divider()
                page
                Divider()
                Footer()
            }
            .navigationTitle(store.page.title)
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                if store.busy {
                    Button(Messages.stop) { store.stop() }
                } else {
                    Button(Messages.scan) { store.scan() }
                }
                Button(Messages.flushSelected) { store.confirmFlush = true }
                    .disabled(store.busy || store.selectedCount == 0)
            }
        }
        .frame(minWidth: 900, minHeight: 600)
        .confirmationDialog(
            String(format: Messages.deleteAcross, Format.bytes(store.selectedTotal), Messages.targets(store.selectedCount)),
            isPresented: $store.confirmFlush,
            titleVisibility: .visible
        ) {
            Button(Messages.flushMenu, role: .destructive) { store.flush() }
            Button(Messages.cancel, role: .cancel) {}
        } message: {
            Text(store.flushTargets.warning)
        }
        .sheet(item: $store.edited) { target in
            TargetEditor(target: target)
        }
        .environment(\.layoutDirection, Localization.isRightToLeft ? .rightToLeft : .leftToRight)
        .id(store.language)
        .onAppear {
            Appearance.stored.apply()
            store.scan()
        }
    }

    @ViewBuilder
    private var page: some View {
        switch store.page {
        case .home: HomePage()
        case .all: AllPage()
        case .audience(let audience): TargetsPage(audience: audience)
        case .charts: ChartsPage()
        case .activity: ActivityPage()
        case .settings: SettingsPage()
        case .about: AboutPage()
        }
    }
}

struct Sidebar: View {
    @EnvironmentObject var store: Store

    private var selection: Binding<Page?> {
        Binding(get: { store.page }, set: { if let page = $0 { store.page = page } })
    }

    var body: some View {
        List(selection: selection) {
            Text(Messages.home).tag(Page.home)
            Section(Messages.scans) {
                row(Messages.all, bytes: store.measuredTotal).tag(Page.all)
                ForEach(Audience.allCases) { audience in
                    row(audience.name, bytes: store.total(of: audience)).tag(Page.audience(audience))
                }
            }
            Section {
                Text(Messages.charts).tag(Page.charts)
                Text(Messages.activity).tag(Page.activity)
            }
            Section {
                Text(Messages.settings).tag(Page.settings)
                Text(Messages.about).tag(Page.about)
            }
        }
        .listStyle(.sidebar)
    }

    private func row(_ name: String, bytes: Int64) -> some View {
        HStack {
            Text(name)
            Spacer()
            if bytes > 0 {
                Text(Format.bytes(bytes))
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct HomePage: View {
    @EnvironmentObject var store: Store

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(Messages.homeTitle).font(.title.bold())
                    Text(Messages.homeLead).foregroundStyle(.secondary)
                }
                step("1", Messages.scan, Messages.homeStepScanText)
                step("2", Messages.choose, Messages.homeStepChooseText)
                step("3", Messages.flushMenu, Messages.homeStepFlushText)
                step("+", Messages.homeOwn, Messages.homeOwnText)
                Text(Messages.homeMore).foregroundStyle(.secondary)
                HStack(spacing: 10) {
                    Button(Messages.scan) { store.scan() }.disabled(store.busy)
                    Button(Messages.all) { store.page = .all }
                    Button(Messages.addTarget) { store.edited = UserTarget() }
                }
            }
            .frame(maxWidth: 640, alignment: .leading)
            .padding(28)
            .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func step(_ number: String, _ title: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Text(number)
                .font(.system(.title3, design: .monospaced).weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 22, alignment: .trailing)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline)
                Text(text).foregroundStyle(.secondary)
            }
        }
    }
}

struct AllPage: View {
    @EnvironmentObject var store: Store

    private func groups(of audience: Audience) -> [TargetGroup] {
        store.groups.filter { $0.audience == audience && $0.items.contains(where: store.isVisible) }
    }

    var body: some View {
        List {
            ForEach(Audience.allCases) { audience in
                let groups = groups(of: audience)
                if !groups.isEmpty {
                    Section(audience.name) {
                        ForEach(groups) { group in
                            GroupSection(group: group)
                        }
                    }
                }
            }
        }
        .listStyle(.inset)
    }
}

struct TargetsPage: View {
    @EnvironmentObject var store: Store
    let audience: Audience

    private var groups: [TargetGroup] {
        store.groups.filter { $0.audience == audience && $0.items.contains(where: store.isVisible) }
    }

    var body: some View {
        if groups.isEmpty {
            VStack(spacing: 12) {
                Text(audience == .mine ? Messages.noOwnTargets : Messages.nothingHere)
                    .foregroundStyle(.secondary)
                if audience == .mine {
                    Button(Messages.addTarget) { store.edited = UserTarget() }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List {
                ForEach(groups) { group in
                    GroupSection(group: group)
                }
            }
            .listStyle(.inset)
        }
    }
}

struct ChartsPage: View {
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                DiskDonut()
                DiskLegend()
            }
            .padding()
            Divider()
            HStack(spacing: 0) {
                LocationChart()
                Divider()
                GroupChart()
            }
        }
    }
}

struct ActivityPage: View {
    var body: some View {
        LogView()
    }
}

struct SettingsPage: View {
    var body: some View {
        ScrollView {
            GeneralSettings()
                .frame(maxWidth: 440)
                .padding(8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct AboutPage: View {
    var body: some View {
        ScrollView {
            AboutSettings()
                .frame(maxWidth: 520)
                .padding(8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct Footer: View {
    @EnvironmentObject var store: Store

    var body: some View {
        HStack(spacing: 8) {
            Button {
                store.page = .activity
            } label: {
                HStack(spacing: 6) {
                    if let entry = store.log.last {
                        Image(systemName: entry.level.icon)
                            .foregroundStyle(entry.level.color)
                        Text(entry.message)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    } else {
                        Text(Messages.noActivityYet)
                    }
                }
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            Spacer()
            Link(Messages.credit, destination: Links.website)
                .foregroundStyle(.secondary)
                .fixedSize()
        }
        .font(.caption)
        .padding(.horizontal)
        .padding(.vertical, 6)
    }
}

struct DiskLine: View {
    @EnvironmentObject var store: Store

    var body: some View {
        HStack(spacing: 14) {
            if let disk = store.disk {
                let expected = max(0, disk.usedFraction - Double(store.selectedTotal) / Double(max(disk.total, 1)))
                Text(String(format: Messages.freeOf, Format.bytes(disk.free), Format.bytes(disk.total)))
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize()
                PercentBar(
                    fraction: expected,
                    behind: disk.usedFraction,
                    tint: disk.usedFraction > 0.9 ? Palette.warning : Palette.otherData,
                    label: store.selectedTotal > 0
                        ? "\(Format.percent(disk.usedFraction)) → \(Format.percent(expected))"
                        : Format.percent(disk.usedFraction)
                )
                if let after = store.expectedFreeAfterFlush, store.selectedTotal > 0 {
                    Text(String(format: Messages.selectedIn, Format.bytes(store.selectedTotal), Messages.targets(store.selectedCount), Format.bytes(after)))
                        .font(.callout.weight(.medium))
                        .foregroundStyle(Palette.selected)
                        .fixedSize()
                }
                if let freed = store.lastFreed {
                    Text(String(format: Messages.freed, Format.bytes(freed)))
                        .font(.callout.weight(.medium))
                        .foregroundStyle(Palette.selected)
                        .fixedSize()
                }
            }
            if let progress = store.progress {
                ProgressView(value: progress.fraction)
                    .frame(width: 90)
                Text(String(format: Messages.progressOf, progress.done, progress.total))
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .fixedSize()
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
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
                    Text(localized(group.name)).font(.headline)
                    Spacer()
                    Text(Format.bytes(store.total(of: group)))
                        .font(.system(.callout, design: .monospaced))
                        .foregroundStyle(.secondary)
                    Button(Messages.all_) { store.setGroup(group, on: true) }
                    Button(Messages.none) { store.setGroup(group, on: false) }
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
            if item.custom {
                Button(Messages.edit) { store.edited = store.userTargets.first { $0.id == item.id } }
                    .buttonStyle(.link)
                    .font(.caption)
            }
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

extension LogLevel {
    var label: String {
        switch self {
        case .info: return Messages.info
        case .error: return Messages.error
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
        case .info: return .secondary
        case .error: return Palette.warning
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
        .background(entry.level == .error ? Palette.warning.opacity(0.12) : Color.clear)
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
                Text(Messages.activityLog)
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
                .onChange(of: store.log.last?.id) { id in
                    if let id { proxy.scrollTo(id, anchor: .bottom) }
                }
            }
        }
    }
}

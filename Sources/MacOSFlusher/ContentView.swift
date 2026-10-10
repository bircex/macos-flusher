import SwiftUI
import AppKit

enum Page: Hashable {
    case home
    case scan
    case reports
    case logs
    case settings
    case about

    var title: String {
        switch self {
        case .home: return Messages.home
        case .scan: return Messages.scan
        case .reports: return Messages.reports
        case .logs: return Messages.logs
        case .settings: return Messages.settings
        case .about: return Messages.about
        }
    }

    var icon: String {
        switch self {
        case .home: return "house"
        case .scan: return "magnifyingglass"
        case .reports: return "chart.bar.doc.horizontal"
        case .logs: return "list.bullet.rectangle"
        case .settings: return "gearshape"
        case .about: return "info.circle"
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
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                        .controlSize(.large)
                }
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
        .id(store.language + " " + store.theme)
        .onAppear {
            Appearance.stored.apply()
            store.scan()
        }
    }

    @ViewBuilder
    private var page: some View {
        switch store.page {
        case .home: HomePage()
        case .scan: ScanPage()
        case .reports: ReportsPage()
        case .logs: LogsPage()
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
            Section {
                HStack(spacing: 9) {
                    Image(nsImage: NSApp.applicationIconImage)
                        .resizable()
                        .frame(width: 22, height: 22)
                    Text(Messages.appName)
                        .font(.headline)
                }
                .padding(.vertical, 2)
            }
            Section {
                ForEach([Page.home, .scan, .reports, .settings, .logs, .about], id: \.self) { page in
                    Label(page.title, systemImage: page.icon).tag(page)
                }
            }
        }
        .listStyle(.sidebar)
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
                    Button(Messages.scan) { store.scan(); store.page = .scan }.disabled(store.busy)
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

struct LogsPage: View {
    var body: some View {
        LogView()
    }
}

struct SettingsPage: View {
    var body: some View {
        ScrollView {
            GeneralSettings()
                .frame(maxWidth: 520)
                .padding(.vertical, 8)
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
                store.page = .logs
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
            Link(destination: Links.repository) {
                Text("© 2026 ") + Text(Messages.credit)
            }
            .foregroundStyle(.secondary)
            .fixedSize()
        }
        .font(.caption)
        .padding(.horizontal)
        .padding(.vertical, 6)
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

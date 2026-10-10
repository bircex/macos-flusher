import AppKit
import SwiftUI

enum Appearance: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    static let key = "appearance"

    var id: String { rawValue }

    var name: String {
        switch self {
        case .system: return Messages.appearanceSystem
        case .light: return Messages.appearanceLight
        case .dark: return Messages.appearanceDark
        }
    }

    var nsAppearance: NSAppearance? {
        switch self {
        case .system: return nil
        case .light: return NSAppearance(named: .aqua)
        case .dark: return NSAppearance(named: .darkAqua)
        }
    }

    static var stored: Appearance {
        Appearance(rawValue: UserDefaults.standard.string(forKey: key) ?? "") ?? .system
    }

    func apply() {
        NSApp.appearance = nsAppearance
    }
}

enum Links {
    static let repository = URL(string: "https://github.com/bircex/macos-flusher")!
    static let website = URL(string: "https://bircex.github.io/macos-flusher/")!
    static let issues = URL(string: "https://github.com/bircex/macos-flusher/issues")!
    static let license = URL(string: "https://github.com/bircex/macos-flusher/blob/main/LICENSE")!
}

enum About {
    static var version: String? {
        guard Bundle.main.bundleIdentifier != nil else { return nil }
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    }

    static var versionLine: String {
        version.map { Messages.version + " " + $0 } ?? Messages.developmentBuild
    }
}

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettings()
                .tabItem { Label(Messages.general, systemImage: "gearshape") }
            AboutSettings()
                .tabItem { Label(Messages.about, systemImage: "info.circle") }
        }
        .frame(width: 440)
    }
}

struct GeneralSettings: View {
    @EnvironmentObject var store: Store
    @AppStorage(Appearance.key) private var appearance = Appearance.system.rawValue

    var body: some View {
        Form {
            Section(Messages.appearance) {
                Picker(Messages.appearance, selection: $appearance) {
                    ForEach(Appearance.allCases) { choice in
                        Text(choice.name).tag(choice.rawValue)
                    }
                }
                .labelsHidden()
                .pickerStyle(.segmented)
                .onChange(of: appearance) { value in
                    (Appearance(rawValue: value) ?? .system).apply()
                }
                ThemeCards(selection: $store.theme)
            }
            Section(Messages.language) {
                Picker(Messages.language, selection: $store.language) {
                    Text(Messages.appearanceSystem).tag(Localization.system)
                    ForEach(Localization.codes, id: \.self) { code in
                        Text(Localization.name(of: code)).tag(code)
                    }
                }
                .labelsHidden()
            }
            Section(Messages.scans) {
                Toggle(Messages.hideEmpty, isOn: $store.hideEmpty)
            }
            Section(Messages.data) {
                Text(Storage.folder.path)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
                Button(Messages.showInFinder) {
                    NSWorkspace.shared.activateFileViewerSelecting([Storage.folder])
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 480)
    }
}

struct ThemeCards: View {
    @Binding var selection: String

    var body: some View {
        HStack(spacing: 10) {
            ForEach(Theme.all) { theme in
                ThemeCard(theme: theme, selected: theme.id == selection) {
                    selection = theme.id
                }
            }
            Spacer(minLength: 0)
        }
    }
}

struct ThemeCard: View {
    let theme: Theme
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                HStack(spacing: 5) {
                    ForEach(Array(theme.swatches.enumerated()), id: \.offset) { _, color in
                        Circle().fill(color).frame(width: 13, height: 13)
                    }
                }
                Text(theme.name)
                    .font(.caption)
                    .foregroundStyle(selected ? .primary : .secondary)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color.secondary.opacity(selected ? 0.16 : 0.07)))
            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(selected ? Color.accentColor : .clear, lineWidth: 1.5))
        }
        .buttonStyle(.plain)
    }
}

struct AboutSettings: View {
    private let links: [(String, URL, String)] = [
        (Messages.repository, Links.repository, "chevron.left.forwardslash.chevron.right"),
        (Messages.website, Links.website, "globe"),
        (Messages.reportProblem, Links.issues, "exclamationmark.bubble"),
        (Messages.license, Links.license, "doc.text"),
    ]

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 10) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 80, height: 80)
                Text(Messages.appName)
                    .font(.title.bold())
                Text(About.versionLine)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.secondary.opacity(0.12)))
            }
            Text(Messages.credit)
                .font(.callout)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .frame(maxWidth: 360)
            VStack(spacing: 1) {
                ForEach(Array(links.enumerated()), id: \.offset) { index, link in
                    if index > 0 { Divider() }
                    Link(destination: link.1) {
                        HStack {
                            Image(systemName: link.2)
                                .frame(width: 18)
                                .foregroundStyle(.secondary)
                            Text(link.0)
                            Spacer()
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(RoundedRectangle(cornerRadius: 10).fill(Color.secondary.opacity(0.07)))
            .frame(maxWidth: 360)
        }
        .padding(28)
        .frame(maxWidth: .infinity)
    }
}

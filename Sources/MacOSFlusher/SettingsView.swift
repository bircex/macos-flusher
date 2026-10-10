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
            Picker(Messages.appearance, selection: $appearance) {
                ForEach(Appearance.allCases) { choice in
                    Text(choice.name).tag(choice.rawValue)
                }
            }
            .onChange(of: appearance) { value in
                (Appearance(rawValue: value) ?? .system).apply()
            }
            Picker(Messages.theme, selection: $store.theme) {
                ForEach(Theme.all) { theme in
                    Text(theme.name).tag(theme.id)
                }
            }
            Picker(Messages.language, selection: $store.language) {
                Text(Messages.appearanceSystem).tag(Localization.system)
                ForEach(Localization.codes, id: \.self) { code in
                    Text(Localization.name(of: code)).tag(code)
                }
            }
            Toggle(Messages.hideEmpty, isOn: $store.hideEmpty)
        }
        .padding(20)
    }
}

struct AboutSettings: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 72, height: 72)
            Text(Messages.appName)
                .font(.title2.bold())
            Text(About.versionLine)
                .foregroundStyle(.secondary)
            Text(Messages.credit)
                .multilineTextAlignment(.center)
            HStack(spacing: 16) {
                Link(Messages.repository, destination: Links.repository)
                Link(Messages.website, destination: Links.website)
                Link(Messages.reportProblem, destination: Links.issues)
                Link(Messages.license, destination: Links.license)
            }
            .font(.callout)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
    }
}

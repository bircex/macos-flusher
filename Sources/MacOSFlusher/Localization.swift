import Foundation

enum Localization {
    static let key = "language"
    static let system = "system"

    static let resources: Bundle = {
        if Bundle.main.path(forResource: "en", ofType: "lproj") != nil { return Bundle.main }
        let sources = URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent("Resources")
        return Bundle(path: sources.path) ?? Bundle.main
    }()

    static var codes: [String] {
        resources.localizations.filter { $0 != "Base" }.sorted()
    }

    static var selected: String {
        UserDefaults.standard.string(forKey: key) ?? system
    }

    static var effective: String {
        selected == system ? (resources.preferredLocalizations.first ?? "en") : selected
    }

    static var isRightToLeft: Bool {
        Locale.Language(identifier: effective).characterDirection == .rightToLeft
    }

    static func bundle(for code: String) -> Bundle {
        guard code != system, let path = resources.path(forResource: code, ofType: "lproj"), let bundle = Bundle(path: path) else {
            return resources
        }
        return bundle
    }

    static func name(of code: String) -> String {
        Locale(identifier: code).localizedString(forLanguageCode: code)?.capitalized(with: Locale(identifier: code)) ?? code
    }
}

func localized(_ key: String) -> String {
    Localization.bundle(for: Localization.selected).localizedString(forKey: key, value: key, table: nil)
}

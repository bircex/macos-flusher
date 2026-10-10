import Foundation
import Testing
@testable import MacOSFlusher

@Suite struct LocalizationTests {
    private let root = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()

    private func table(_ code: String) throws -> [String: String] {
        let file = root.appendingPathComponent("Sources/MacOSFlusher/Resources/\(code).lproj/Localizable.strings")
        let plist = try PropertyListSerialization.propertyList(from: Data(contentsOf: file), format: nil)
        return plist as? [String: String] ?? [:]
    }

    private func placeholders(_ text: String) -> [String] {
        text.components(separatedBy: "%").dropFirst().map { String($0.prefix(1)) }.filter { "@d".contains($0) }.sorted()
    }

    @Test func threeLanguagesToBeginWith() {
        #expect(Localization.codes == ["ar", "en", "tr"])
        #expect(Localization.name(of: "en") == "English")
        #expect(Localization.name(of: "tr") == "Türkçe")
        #expect(Localization.name(of: "ar") == "العربية")
    }

    @Test func englishKeysEqualTheirValues() throws {
        for (key, value) in try table("en") {
            #expect(key == value, "\(key)")
        }
    }

    @Test(arguments: ["tr", "ar"])
    func languageMatchesEnglish(code: String) throws {
        let english = try table("en")
        let other = try table(code)
        #expect(Set(other.keys) == Set(english.keys), "\(code) keys differ from English")
        for (key, value) in other {
            #expect(!value.trimmingCharacters(in: .whitespaces).isEmpty, "\(code): empty value for \(key)")
            #expect(placeholders(value) == placeholders(key), "\(code): placeholders differ for \(key)")
        }
    }

    @Test func everyKeyInTheCodeExists() throws {
        let english = try table("en")
        let sources = root.appendingPathComponent("Sources/MacOSFlusher")
        var used: Set<String> = []
        for name in try FileManager.default.contentsOfDirectory(atPath: sources.path) where name.hasSuffix(".swift") {
            let text = try String(contentsOf: sources.appendingPathComponent(name), encoding: .utf8)
            for part in text.components(separatedBy: "localized(\"").dropFirst() {
                var key = ""
                var escaped = false
                for character in part {
                    if escaped { key.append(character); escaped = false; continue }
                    if character == "\\" { escaped = true; continue }
                    if character == "\"" { break }
                    key.append(character)
                }
                used.insert(key)
            }
        }
        #expect(used.count > 80)
        for key in used {
            #expect(english[key] != nil, "missing key: \(key)")
        }
        for group in Targets.groups {
            #expect(english[group.name] != nil, "missing group name: \(group.name)")
        }
        for name in ["Applications", "Disk image", "Other Docker data", "Library", "System files", "Docker", "Other home items", "Everything else"] {
            #expect(english[name] != nil, "missing location name: \(name)")
        }
    }

    @Test func fallsBackToTheKey() {
        #expect(Localization.bundle(for: "tr").localizedString(forKey: "no such key", value: "no such key", table: nil) == "no such key")
        #expect(Localization.bundle(for: "zz").bundlePath == Localization.resources.bundlePath)
    }

    @Test func translates() {
        #expect(Localization.bundle(for: "tr").localizedString(forKey: "Settings", value: nil, table: nil) == "Ayarlar")
        #expect(Localization.bundle(for: "ar").localizedString(forKey: "Settings", value: nil, table: nil) == "الإعدادات")
        #expect(Localization.bundle(for: "en").localizedString(forKey: "Settings", value: nil, table: nil) == "Settings")
    }

    @Test func directionOfArabic() {
        #expect(Locale.Language(identifier: "ar").characterDirection == .rightToLeft)
        #expect(Locale.Language(identifier: "tr").characterDirection == .leftToRight)
    }
}

import AppKit
import Testing
@testable import MacOSFlusher

@Suite struct SettingsTests {
    @Test func appearanceFollowsTheSystemByDefault() {
        #expect(Appearance.system.nsAppearance == nil)
        #expect(Appearance(rawValue: "") == nil)
        #expect(Appearance.light.nsAppearance?.name == .aqua)
        #expect(Appearance.dark.nsAppearance?.name == .darkAqua)
    }

    @Test func appearanceNames() {
        #expect(Appearance.allCases.map(\.name) == ["System", "Light", "Dark"])
    }

    @Test func versionOutsideTheAppIsMarked() {
        #expect(About.version == nil)
        #expect(About.versionLine == "Development build")
    }

    @Test func creditNamesTheAssistant() {
        #expect(Messages.credit == "Made by BirceX, Recep's AI assistant.")
    }
}

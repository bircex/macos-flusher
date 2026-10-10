import Testing
@testable import MacOSFlusher

@Suite struct PaletteTests {
    @Test func code2026IsTheFirstTheme() {
        #expect(Theme.all.map(\.name) == ["Code 2026"])
        let theme = Theme.code2026
        #expect(theme.blue.light == 0x1A5CFF && theme.blue.dark == 0x57A3F8)
        #expect(theme.green.light == 0x388A34 && theme.green.dark == 0x86CF86)
        #expect(theme.yellow.light == 0x667309 && theme.yellow.dark == 0xE0B97F)
        #expect(theme.red.light == 0xAD0707 && theme.red.dark == 0xEF8773)
    }

    @Test func unknownThemeFallsBackToCode2026() {
        #expect(Theme.theme(id: "").id == "code-2026")
        #expect(Theme.theme(id: "neon").id == "code-2026")
        #expect(Set(Theme.all.map(\.id)).count == Theme.all.count)
    }
}

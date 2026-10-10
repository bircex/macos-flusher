import Testing
@testable import MacOSFlusher

@Suite struct PaletteTests {
    @Test func usesTheCode2026Colours() {
        #expect(Palette.blue.light == 0x1A5CFF && Palette.blue.dark == 0x57A3F8)
        #expect(Palette.green.light == 0x388A34 && Palette.green.dark == 0x86CF86)
        #expect(Palette.yellow.light == 0x667309 && Palette.yellow.dark == 0xE0B97F)
        #expect(Palette.red.light == 0xAD0707 && Palette.red.dark == 0xEF8773)
    }
}

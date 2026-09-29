import Testing
@testable import MacOSFlusher

@Suite struct MeasurerTests {
    @Test func measuresPaths() async throws {
        let folder = try Folder()
        defer { folder.remove() }
        try folder.add("cache/blob", bytes: 200_000)
        let measurement = await Measurer.measure(Target("sample", "Sample", [folder.path + "/cache"]))
        guard case .measured(let bytes) = measurement.state else {
            Issue.record("expected a size, got \(measurement.state)")
            return
        }
        #expect(bytes >= 200_000)
        #expect(measurement.paths[folder.path + "/cache"] == bytes)
    }

    @Test func missingFolderIsEmpty() async throws {
        let folder = try Folder()
        defer { folder.remove() }
        let measurement = await Measurer.measure(Target("sample", "Sample", [folder.path + "/missing"]))
        #expect(measurement.state == .measured(0))
    }

    @Test func missingToolIsUnavailable() async {
        let item = Target("sample", "Sample", ["/private/tmp"], requires: "macos-flusher-no-such-tool")
        #expect(await Measurer.measure(item).state == .unavailable)
    }

    @Test func sizeCommandWins() async {
        let item = Target("sample", "Sample", ["/private/tmp"], sizeCommand: "print 1.5GB; print 500MB")
        #expect(await Measurer.measure(item).state == .measured(2_000_000_000))
    }

    @Test func formatsPercent() {
        #expect(Format.percent(0) == "0%")
        #expect(Format.percent(0.945) == "95%")
        #expect(Format.percent(1) == "100%")
    }
}

import Testing
@testable import MacOSFlusher

@Suite struct WarningTests {
    private let cache = Target("a", "npm cache", ["~/a"])
    private let modules = Target("b", "Go module cache", ["~/b"], risk: .redownload)
    private let models = Target("c", "Ollama models", ["~/c"], risk: .redownload)
    private let trash = Target("d", "Trash", ["~/d"], risk: .data)

    @Test func cachesOnly() {
        #expect([cache].warning == """
            Caches are rebuilt on demand.
            Named Docker volumes and project files are never touched.
            """)
    }

    @Test func namesWhatIsSlowAndWhatIsGone() {
        #expect([cache, modules, trash, models].warning == """
            Caches are rebuilt on demand.
            Slow to get back: Go module cache, Ollama models.
            Deleted for good: Trash.
            Named Docker volumes and project files are never touched.
            """)
    }

    @Test func withoutCaches() {
        #expect([trash].warning == """
            Deleted for good: Trash.
            Named Docker volumes and project files are never touched.
            """)
    }

    @Test func countsTargets() {
        #expect(Messages.targets(0) == "0 targets")
        #expect(Messages.targets(1) == "1 target")
        #expect(Messages.targets(72) == "72 targets")
    }

    @Test func labels() {
        #expect(Risk.rebuilds.label == nil)
        #expect(Risk.redownload.label == "slow to get back")
        #expect(Risk.data.label == "deleted for good")
    }
}

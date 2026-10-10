import Testing
@testable import MacOSFlusher

@MainActor
@Suite struct StoreTests {
    private func target(_ id: String, in folder: Folder, bytes: Int = 200_000) throws -> Target {
        try folder.add(id + "/blob", bytes: bytes)
        return Target(id, "Sample " + id, [folder.path + "/" + id])
    }

    @Test func startsIdle() throws {
        let folder = try Folder()
        defer { folder.remove() }
        #expect(folder.store().idle)
    }

    @Test func measuresOnlyWhatIsAsked() async throws {
        let folder = try Folder()
        defer { folder.remove() }
        let store = folder.store()
        let first = try target("first", in: folder)
        let second = try target("second", in: folder, bytes: 400_000)
        await store.measure([first, second])
        #expect((store.size(of: first) ?? 0) >= 200_000)
        #expect((store.size(of: second) ?? 0) >= 400_000)
        #expect(store.states.count == 2)
        #expect(store.progress == nil)
    }

    @Test func cleansAndReports() async throws {
        let folder = try Folder()
        defer { folder.remove() }
        let store = folder.store()
        let item = try target("first", in: folder)
        await store.measure([item])
        let results = await store.clean([item])
        #expect(results.count == 1)
        #expect(results[0].id == "first")
        #expect(results[0].status == .cleaned)
        #expect(results[0].before >= 200_000)
        #expect(results[0].after == 0)
        #expect(results.freed == results[0].before)
        #expect(folder.exists("first"))
        #expect(folder.contents("first").isEmpty)
        #expect(store.size(of: item) == 0)
        #expect(store.progress == nil)
        #expect(store.log.last?.message == "Flushed Sample first")
    }

    @Test func reportsFailedCommand() async throws {
        let folder = try Folder()
        defer { folder.remove() }
        let store = folder.store()
        try folder.add("first/blob", bytes: 200_000)
        let item = Target("first", "Sample first", [folder.path + "/first"], flush: .command("print nope; exit 2"))
        await store.measure([item])
        let results = await store.clean([item])
        #expect(results[0].status == .failed)
        #expect(results[0].message == "nope")
        #expect(results[0].after == results[0].before)
        #expect(results.freed == 0)
        #expect(folder.contents("first") == ["blob"])
        #expect(store.log.last?.level == .error)
        #expect(store.log.last?.message == "Sample first: nope")
    }

    @Test func stopsWhenTheGoalIsReached() async throws {
        let folder = try Folder()
        defer { folder.remove() }
        let store = folder.store()
        let items = [try target("first", in: folder), try target("second", in: folder), try target("third", in: folder)]
        await store.measure(items)
        let results = await store.clean(items, until: { $0.freed >= 200_000 })
        #expect(results.map(\.status) == [.cleaned, .skipped, .skipped])
        #expect(results.freed == results[0].before)
        #expect(folder.contents("first").isEmpty)
        #expect(folder.contents("second") == ["blob"])
        #expect(folder.contents("third") == ["blob"])
    }

    @Test func skipsEverythingWhenCancelled() async throws {
        let folder = try Folder()
        defer { folder.remove() }
        let store = folder.store()
        let items = [try target("first", in: folder), try target("second", in: folder)]
        await store.measure(items)
        let work = Task { @MainActor in await store.clean(items) }
        work.cancel()
        let results = await work.value
        #expect(results.map(\.status) == [.skipped, .skipped])
        #expect(results.freed == 0)
        #expect(folder.contents("first") == ["blob"])
        #expect(folder.contents("second") == ["blob"])
    }

    @Test func freedCountsOnlyWhatRan() {
        let results = [
            ItemResult(id: "a", name: "A", before: 500, after: 100, status: .cleaned, message: ""),
            ItemResult(id: "b", name: "B", before: 300, after: 300, status: .failed, message: "no"),
            ItemResult(id: "c", name: "C", before: 900, after: 900, status: .skipped, message: ""),
        ]
        #expect(results.freed == 400)
    }

    @Test func freedIsNeverNegative() {
        let results = [ItemResult(id: "a", name: "A", before: 100, after: 250, status: .cleaned, message: "")]
        #expect(results.freed == 0)
    }

    @Test func freedIgnoresSkippedSizes() {
        let stopped = [
            ItemResult(id: "a", name: "A", before: 10_000, after: 0, status: .cleaned, message: ""),
            ItemResult(id: "b", name: "B", before: 5_000, after: 5_000, status: .skipped, message: ""),
        ]
        #expect(stopped.freed == 10_000)
    }
}

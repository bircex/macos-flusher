import Foundation
import Testing
@testable import MacOSFlusher

@MainActor
@Suite struct PagesTests {
    @Test func startsOnEveryone() throws {
        let folder = try Folder()
        defer { folder.remove() }
        #expect(folder.store().page == .audience(.everyone))
    }

    @Test func titles() {
        #expect(Page.audience(.developers).title == "Developers")
        #expect(Page.audience(.mine).title == "My targets")
        #expect(Page.charts.title == "Charts")
        #expect(Page.activity.title == "Activity")
    }

    @Test func totalOfAnAudienceAddsUpItsGroups() async throws {
        let folder = try Folder()
        defer { folder.remove() }
        let store = folder.store()
        try folder.add("home/Movies/cache/blob", bytes: 300_000)
        let mine = UserTarget(name: "Old renders", paths: [folder.home + "/Movies/cache"], accepted: Date()).target
        store.save(UserTarget(id: mine.id, name: mine.name, paths: mine.paths, accepted: Date()))
        await store.measure([mine])
        #expect(store.total(of: .mine) >= 300_000)
        #expect(store.total(of: .developers) == 0)
        #expect(store.total(of: .mine) == store.total(of: store.groups.last!))
    }
}

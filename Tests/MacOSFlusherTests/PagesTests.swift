import Foundation
import Testing
@testable import MacOSFlusher

@MainActor
@Suite struct PagesTests {
    @Test func startsOnHome() throws {
        let folder = try Folder()
        defer { folder.remove() }
        #expect(folder.store().page == .home)
    }

    @Test func titles() {
        #expect(Page.home.title == "Home")
        #expect(Page.scan.title == "Scan")
        #expect(Page.reports.title == "Reports")
        #expect(Page.logs.title == "Logs")
        #expect(Page.settings.title == "Settings")
        #expect(Page.about.title == "About")
    }

    @Test func scanRowsCarryTheirCategoryAndGroup() throws {
        let folder = try Folder()
        defer { folder.remove() }
        let store = folder.store()
        store.hideEmpty = false
        let row = store.scanRows.first { $0.id == "chrome" }
        #expect(row?.category == .browsers)
        #expect(row?.groupName == "Web browsers")
        #expect(row?.custom == false)
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

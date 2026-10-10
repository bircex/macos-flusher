import Foundation
import Testing
@testable import MacOSFlusher

@MainActor
@Suite struct UserTargetTests {
    private func accepted(_ name: String, paths: [String] = [], command: String? = nil) -> UserTarget {
        UserTarget(name: name, paths: paths, command: command, accepted: Date())
    }

    @Test func foldersAreEmptied() {
        let item = accepted("Old renders", paths: ["~/Movies/Renders/cache", "~/Movies/Renders/tmp"]).target
        guard case .removePaths = item.flush else {
            Issue.record("expected the folders to be emptied")
            return
        }
        #expect(item.detail == "~/Movies/Renders/cache, ~/Movies/Renders/tmp")
        #expect(item.risk == .data)
        #expect(item.custom)
        #expect(!item.defaultOn)
    }

    @Test func commandReplacesEmptying() {
        let item = accepted("Prune", paths: ["~/Movies/Renders/cache"], command: "example --prune").target
        guard case .command(let command) = item.flush else {
            Issue.record("expected the command to run")
            return
        }
        #expect(command == "example --prune")
        #expect(item.detail == "$ example --prune")
        #expect(item.paths == ["~/Movies/Renders/cache"])
    }

    @Test func idsAreMarkedAndUnique() {
        let first = UserTarget()
        let second = UserTarget()
        #expect(first.id.hasPrefix("user-"))
        #expect(first.id != second.id)
        #expect(!Targets.allItems.contains { $0.id.hasPrefix("user-") })
    }

    @Test func savedTargetsAreListedLast() throws {
        let folder = try Folder()
        defer { folder.remove() }
        let store = folder.store()
        #expect(store.groups.count == Targets.groups.count)
        store.save(accepted("Old renders", paths: [folder.home + "/Movies/cache"]))
        #expect(store.groups.count == Targets.groups.count + 1)
        #expect(store.groups.last?.id == Store.mine)
        #expect(store.groups.last?.audience == .mine)
        #expect(store.groups.last?.items.map(\.name) == ["Old renders"])
        #expect(store.allItems.count == Targets.allItems.count + 1)
    }

    @Test func savedTargetsSurviveARestart() throws {
        let folder = try Folder()
        defer { folder.remove() }
        let target = accepted("Old renders", paths: [folder.home + "/Movies/cache"])
        folder.store().save(target)
        let restarted = folder.store()
        #expect(restarted.userTargets.map(\.id) == [target.id])
        #expect(restarted.userTargets.first?.paths == target.paths)
        #expect(restarted.groups.last?.items.first?.id == target.id)
    }

    @Test func savingAgainReplaces() throws {
        let folder = try Folder()
        defer { folder.remove() }
        let store = folder.store()
        var target = accepted("Old renders", paths: [folder.home + "/Movies/cache"])
        store.save(target)
        target.name = "Renders"
        store.save(target)
        #expect(store.userTargets.map(\.name) == ["Renders"])
        #expect(folder.store().userTargets.map(\.name) == ["Renders"])
    }

    @Test func startsUnselected() throws {
        let folder = try Folder()
        defer { folder.remove() }
        let store = folder.store()
        let target = accepted("Old renders", paths: [folder.home + "/Movies/cache"])
        store.save(target)
        #expect(!store.selected.contains(target.id))
        #expect(!folder.store().selected.contains(target.id))
    }

    @Test func unconfirmedTargetsAreNotListed() throws {
        let folder = try Folder()
        defer { folder.remove() }
        let store = folder.store()
        store.save(UserTarget(name: "Typed into the file", paths: [folder.home + "/Movies/cache"]))
        #expect(store.userTargets.count == 1)
        #expect(store.groups.count == Targets.groups.count)
    }

    @Test func staysVisibleWhenEmpty() async throws {
        let folder = try Folder()
        defer { folder.remove() }
        let store = folder.store()
        let mine = accepted("Old renders", paths: [folder.home + "/Movies/cache"]).target
        let builtIn = Target("sample", "Sample", [folder.home + "/Movies/other"])
        await store.measure([mine, builtIn])
        #expect(store.hideEmpty)
        #expect(store.size(of: mine) == 0)
        #expect(store.isVisible(mine))
        #expect(!store.isVisible(builtIn))
    }

    @Test func commandWithoutFoldersHasNoSize() async {
        let item = accepted("Prune", command: "example --prune").target
        #expect(await Measurer.measure(item).state == .unknown)
        #expect(await Measurer.measure(Target("sample", "Sample")).state == .measured(0))
    }

    @Test func removingForgetsEverything() throws {
        let folder = try Folder()
        defer { folder.remove() }
        let store = folder.store()
        let target = accepted("Old renders", paths: [folder.home + "/Movies/cache"])
        store.save(target)
        store.toggle(target.target, on: true)
        store.remove(target)
        #expect(store.userTargets.isEmpty)
        #expect(!store.selected.contains(target.id))
        #expect(store.groups.count == Targets.groups.count)
        #expect(folder.store().userTargets.isEmpty)
    }

    @Test func cleansAFolderInsideHome() async throws {
        let folder = try Folder()
        defer { folder.remove() }
        try folder.add("home/Movies/cache/blob", bytes: 200_000)
        let store = folder.store()
        let item = accepted("Old renders", paths: [folder.home + "/Movies/cache"]).target
        await store.measure([item])
        let results = await store.clean([item])
        #expect(results[0].status == .cleaned)
        #expect(results.freed >= 200_000)
        #expect(folder.exists("home/Movies/cache"))
        #expect(folder.contents("home/Movies/cache").isEmpty)
    }

    @Test func refusesAFolderThatMovedOutsideHome() async throws {
        let folder = try Folder()
        defer { folder.remove() }
        try folder.add("outside/keep", bytes: 200_000)
        try folder.add("home/Movies/placeholder")
        try FileManager.default.createSymbolicLink(atPath: folder.home + "/Movies/cache", withDestinationPath: folder.path + "/outside")
        let store = folder.store()
        let item = accepted("Old renders", paths: [folder.home + "/Movies/cache"]).target
        let results = await store.clean([item])
        #expect(results[0].status == .failed)
        #expect(results[0].message == Messages.outsideHome)
        #expect(results.freed == 0)
        #expect(folder.contents("outside") == ["keep"])
        #expect(store.log.last?.level == .error)
    }

    @Test func builtInTargetsSkipTheFolderRules() async throws {
        let folder = try Folder()
        defer { folder.remove() }
        try folder.add("outside/cache/blob", bytes: 200_000)
        let store = folder.store()
        let item = Target("sample", "Sample", [folder.path + "/outside/cache"])
        await store.measure([item])
        let results = await store.clean([item])
        #expect(results[0].status == .cleaned)
        #expect(folder.contents("outside/cache").isEmpty)
    }

    @Test func reportsABrokenFile() throws {
        let folder = try Folder()
        defer { folder.remove() }
        try folder.add("data/placeholder")
        try Data("not json".utf8).write(to: folder.data.appendingPathComponent("targets.json"))
        let store = folder.store()
        #expect(store.userTargets.isEmpty)
        #expect(store.log.last?.level == .error)
        #expect(store.log.last?.message == "My targets could not be read. The file was kept as targets.broken.json.")
        #expect(folder.exists("data/targets.broken.json"))
    }
}

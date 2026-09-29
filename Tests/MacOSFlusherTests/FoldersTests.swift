import Foundation
import Testing
@testable import MacOSFlusher

@Suite struct FoldersTests {
    private func refusal(_ path: String, in folder: Folder) -> String? {
        Folders.refusal(of: path, home: folder.home, own: folder.home + "/Library/Application Support/MacOS Flusher")
    }

    @Test(arguments: [
        "~/Movies/Renders",
        "~/Movies/Renders/cache",
        "~/Library/Caches/com.example.app",
        "~/Library/Application Support/Example/Cache",
        "~/.cache/example",
    ])
    func allows(path: String) throws {
        let folder = try Folder()
        defer { folder.remove() }
        #expect(refusal(path, in: folder) == nil)
    }

    @Test func allowsAbsolutePathsInsideHome() throws {
        let folder = try Folder()
        defer { folder.remove() }
        #expect(refusal(folder.home + "/Movies/Renders", in: folder) == nil)
    }

    @Test(arguments: [
        ("Movies/Renders", Messages.notAPath),
        ("~", Messages.notAPath),
        ("~/Movies/*", Messages.noWildcards),
        ("~/Movies/cache?", Messages.noWildcards),
        ("~/Movies/../../outside/cache", Messages.noParent),
        ("~/Documents", Messages.tooShallow),
        ("~/Desktop", Messages.tooShallow),
        ("~/Downloads", Messages.tooShallow),
        ("~/Library", Messages.tooShallow),
        ("~/Library/Caches", Messages.tooShallow),
        ("~/Library/Application Support", Messages.tooShallow),
        ("~/", Messages.outsideHome),
        ("/etc/example/cache", Messages.outsideHome),
        ("/Applications/Example.app/Contents", Messages.outsideHome),
        ("~/Library/Application Support/MacOS Flusher", Messages.ownData),
        ("~/Library/Application Support/MacOS Flusher/old", Messages.ownData),
    ])
    func refuses(path: String, reason: String) throws {
        let folder = try Folder()
        defer { folder.remove() }
        #expect(refusal(path, in: folder) == reason)
    }

    @Test func refusesALinkThatLeavesHome() throws {
        let folder = try Folder()
        defer { folder.remove() }
        try folder.add("outside/keep")
        try folder.add("home/Movies/placeholder")
        try FileManager.default.createSymbolicLink(atPath: folder.home + "/Movies/link", withDestinationPath: folder.path + "/outside")
        #expect(refusal("~/Movies/link", in: folder) == Messages.outsideHome)
    }

    @Test func refusesALinkToTheTopOfHome() throws {
        let folder = try Folder()
        defer { folder.remove() }
        try folder.add("home/Documents/keep")
        try folder.add("home/Movies/placeholder")
        try FileManager.default.createSymbolicLink(atPath: folder.home + "/Movies/link", withDestinationPath: folder.home + "/Documents")
        #expect(refusal("~/Movies/link", in: folder) == Messages.tooShallow)
    }
}

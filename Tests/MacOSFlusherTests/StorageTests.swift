import Foundation
import Testing
@testable import MacOSFlusher

@Suite struct StorageTests {
    private let sample = [
        UserTarget(id: "user-1", name: "Old renders", paths: ["~/Movies/Renders/cache"], accepted: Date(timeIntervalSince1970: 1_790_000_000)),
        UserTarget(id: "user-2", name: "Prune", command: "docker system prune -f", accepted: Date(timeIntervalSince1970: 1_790_000_100)),
    ]

    private func loaded(from folder: Folder) -> [UserTarget]? {
        if case .value(let targets) = Storage.load("targets", from: folder.data) as Loaded<[UserTarget]> { return targets }
        return nil
    }

    @Test func missingFile() throws {
        let folder = try Folder()
        defer { folder.remove() }
        guard case .missing = Storage.load("targets", from: folder.data) as Loaded<[UserTarget]> else {
            Issue.record("expected a missing file")
            return
        }
    }

    @Test func savesAndLoads() throws {
        let folder = try Folder()
        defer { folder.remove() }
        try Storage.save(sample, as: "targets", in: folder.data)
        #expect(loaded(from: folder) == sample)
        #expect(folder.contents("data") == ["targets.json"])
    }

    @Test func readsTheDocumentedFormat() throws {
        let folder = try Folder()
        defer { folder.remove() }
        try folder.add("data/placeholder")
        try Data("""
            [
              {
                "accepted" : "2026-09-29T10:00:00Z",
                "id" : "user-1",
                "name" : "Old renders",
                "paths" : [ "~/Movies/Renders/cache" ]
              }
            ]
            """.utf8).write(to: folder.data.appendingPathComponent("targets.json"))
        let targets = loaded(from: folder)
        #expect(targets?.count == 1)
        #expect(targets?.first?.paths == ["~/Movies/Renders/cache"])
        #expect(targets?.first?.command == nil)
        #expect(targets?.first?.accepted == ISO8601DateFormatter().date(from: "2026-09-29T10:00:00Z"))
    }

    @Test func keepsABrokenFile() throws {
        let folder = try Folder()
        defer { folder.remove() }
        try folder.add("data/placeholder")
        let file = folder.data.appendingPathComponent("targets.json")
        try Data("first {".utf8).write(to: file)
        guard case .broken(let first) = Storage.load("targets", from: folder.data) as Loaded<[UserTarget]> else {
            Issue.record("expected a broken file")
            return
        }
        try Data("second {".utf8).write(to: file)
        guard case .broken(let second) = Storage.load("targets", from: folder.data) as Loaded<[UserTarget]> else {
            Issue.record("expected a broken file")
            return
        }
        #expect(first == "targets.broken.json")
        #expect(second == "targets.broken.2.json")
        #expect(!folder.exists("data/targets.json"))
        let older = try String(contentsOf: folder.data.appendingPathComponent(first), encoding: .utf8)
        let newer = try String(contentsOf: folder.data.appendingPathComponent(second), encoding: .utf8)
        #expect(older == "first {")
        #expect(newer == "second {")
    }
}

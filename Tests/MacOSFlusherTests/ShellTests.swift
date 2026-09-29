import Foundation
import Testing
@testable import MacOSFlusher

@Suite struct ShellTests {
    @Test(arguments: [
        ("0B", Int64(0)),
        ("512", 512),
        ("1.5kB", 1_500),
        ("2KiB", 2_048),
        ("3MB", 3_000_000),
        ("1MiB", 1_048_576),
        ("1.2GB", 1_200_000_000),
        ("1GiB", 1_073_741_824),
        ("2TB", 2_000_000_000_000),
        ("  4MB", 4_000_000),
        ("none", 0),
    ])
    func parsesSize(text: String, bytes: Int64) {
        #expect(Shell.parseSize(text) == bytes)
    }

    @Test func addsUpLines() {
        #expect(Shell.parseSizes("1MB\n2MB\n\n500kB\n") == 3_500_000)
        #expect(Shell.parseSizes("") == 0)
    }

    @Test func expandsHome() {
        #expect(Shell.expand("~/") == [Shell.home + "/"])
    }

    @Test func expandsOnlyWhatExists() throws {
        let folder = try Folder()
        defer { folder.remove() }
        try folder.add("one/file")
        try folder.add("two/file")
        #expect(Shell.expand(folder.path + "/one") == [folder.path + "/one"])
        #expect(Shell.expand(folder.path + "/missing").isEmpty)
        #expect(Shell.expand(folder.path + "/*").sorted() == [folder.path + "/one", folder.path + "/two"])
        #expect(Shell.expand(folder.path + "/none-*").isEmpty)
    }

    @Test func measuresFolders() async throws {
        let folder = try Folder()
        defer { folder.remove() }
        try folder.add("cache/blob", bytes: 300_000)
        let sizes = await Shell.sizesOfPaths([folder.path + "/cache", folder.path + "/missing"])
        #expect(sizes.keys.sorted() == [folder.path + "/cache"])
        #expect((sizes[folder.path + "/cache"] ?? 0) >= 300_000)
    }

    @Test func emptiesFolderAndKeepsIt() async throws {
        let folder = try Folder()
        defer { folder.remove() }
        try folder.add("cache/a")
        try folder.add("cache/nested/b")
        try folder.add("other/c")
        let result = await Shell.removePaths([folder.path + "/cache"])
        #expect(result.status == 0)
        #expect(folder.exists("cache"))
        #expect(folder.contents("cache").isEmpty)
        #expect(folder.contents("other") == ["c"])
    }

    @Test func removesGlobMatchesWhole() async throws {
        let folder = try Folder()
        defer { folder.remove() }
        try folder.add("run-1/a")
        try folder.add("run-2/b")
        try folder.add("keep/c")
        let result = await Shell.removePaths([folder.path + "/run-*"])
        #expect(result.status == 0)
        #expect(folder.contents() == ["keep"])
    }

    @Test func missingPathIsNotAFailure() async throws {
        let folder = try Folder()
        defer { folder.remove() }
        let result = await Shell.removePaths([folder.path + "/missing"])
        #expect(result.status == 0)
        #expect(result.output.isEmpty)
    }

    @Test func returnsStatusAndOutput() async {
        let result = await Shell.command("print out; print err >&2; exit 3")
        #expect(result.status == 3)
        #expect(result.output == "out\nerr\n")
    }

    @Test func keepsLargeOutput() async {
        let result = await Shell.command("head -c 300000 /dev/zero | tr '\\0' 'x'")
        #expect(result.status == 0)
        #expect(result.output.count == 300_000)
    }

    @Test func reportsLaunchFailure() async {
        let result = await Shell.run("/nonexistent/binary", [])
        #expect(result.status == 127)
    }

    @Test func findsBinaries() {
        #expect(Shell.exists(binary: "ls"))
        #expect(!Shell.exists(binary: "macos-flusher-no-such-tool"))
    }

    @Test func stopsAfterTimeout() async {
        let started = Date()
        let result = await Shell.run("/bin/sleep", ["30"], timeout: 0.5)
        #expect(result.status == Shell.timedOut)
        #expect(Date().timeIntervalSince(started) < 2)
    }

    @Test func timeoutKeepsOutputAndStopsChildren() async throws {
        let marker = "300.\(Int.random(in: 100_000...999_999))"
        let started = Date()
        let result = await Shell.command("print started; sleep \(marker) & sleep \(marker); wait", timeout: 0.5)
        #expect(result.status == Shell.timedOut)
        #expect(result.output == "started\n")
        #expect(Date().timeIntervalSince(started) < 2)
        try await Task.sleep(nanoseconds: 500_000_000)
        let left = await Shell.run("/usr/bin/pgrep", ["-f", "sleep \(marker)"])
        #expect(left.output.isEmpty)
    }

    @Test func killsWhatIgnoresTermination() async throws {
        let marker = "300.\(Int.random(in: 100_000...999_999))"
        let started = Date()
        let result = await Shell.command("trap '' TERM; sleep \(marker)", timeout: 0.5)
        #expect(result.status == Shell.timedOut)
        #expect(Date().timeIntervalSince(started) < 2)
        try await Task.sleep(nanoseconds: 3_000_000_000)
        let left = await Shell.run("/usr/bin/pgrep", ["-f", "sleep \(marker)"])
        #expect(left.output.isEmpty)
    }

    @Test func fastCommandIgnoresTimeout() async {
        let result = await Shell.command("print done", timeout: 30)
        #expect(result.status == 0)
        #expect(result.output == "done\n")
    }
}

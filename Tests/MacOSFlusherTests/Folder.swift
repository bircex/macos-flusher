import Foundation

struct Folder {
    let path: String

    init() throws {
        path = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacOSFlusherTests-" + UUID().uuidString)
            .resolvingSymlinksInPath()
            .path
        try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true)
    }

    func add(_ name: String, bytes: Int = 1) throws {
        let file = path + "/" + name
        try FileManager.default.createDirectory(atPath: (file as NSString).deletingLastPathComponent, withIntermediateDirectories: true)
        try Data(repeating: 1, count: bytes).write(to: URL(fileURLWithPath: file))
    }

    func contents(_ name: String = "") -> [String] {
        ((try? FileManager.default.contentsOfDirectory(atPath: path + "/" + name)) ?? []).sorted()
    }

    func exists(_ name: String) -> Bool {
        FileManager.default.fileExists(atPath: path + "/" + name)
    }

    func remove() {
        try? FileManager.default.removeItem(atPath: path)
    }
}

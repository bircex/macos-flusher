import Foundation

struct UserTarget: Codable, Identifiable, Equatable, Sendable {
    var id: String
    var name: String
    var paths: [String]
    var command: String?
    var accepted: Date?

    init(id: String = "user-" + UUID().uuidString.lowercased(), name: String = "", paths: [String] = [], command: String? = nil, accepted: Date? = nil) {
        self.id = id
        self.name = name
        self.paths = paths
        self.command = command
        self.accepted = accepted
    }

    var target: Target {
        Target(
            id,
            name,
            paths,
            detail: command.map { "$ " + $0 },
            flush: command.map(FlushAction.command) ?? .removePaths,
            risk: .data,
            custom: true
        )
    }
}

enum Folders {
    static func refusal(of path: String, home: String, own: String) -> String? {
        if path.contains("*") || path.contains("?") { return Messages.noWildcards }
        let expanded: String
        if path.hasPrefix("~/") {
            expanded = home + path.dropFirst(1)
        } else if path.hasPrefix("/") {
            expanded = path
        } else {
            return Messages.notAPath
        }
        if expanded.split(separator: "/").contains("..") { return Messages.noParent }
        let root = resolved(home)
        let folder = resolved(expanded)
        guard folder.hasPrefix(root + "/") else { return Messages.outsideHome }
        let parts = folder.dropFirst(root.count + 1).split(separator: "/")
        if parts.count < (parts.first == "Library" ? 3 : 2) { return Messages.tooShallow }
        let data = resolved(own)
        if folder == data || folder.hasPrefix(data + "/") { return Messages.ownData }
        return nil
    }

    private static func resolved(_ path: String) -> String {
        URL(fileURLWithPath: path).resolvingSymlinksInPath().path
    }
}

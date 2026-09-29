import Foundation
import Testing
@testable import MacOSFlusher

@Suite struct DocsTests {
    private let site: String
    private let rows: [String: String]
    private let bundle: String

    init() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        site = try String(contentsOf: root.appendingPathComponent("docs/index.html"), encoding: .utf8)
        let info = try PropertyListSerialization.propertyList(from: Data(contentsOf: root.appendingPathComponent("Info.plist")), format: nil)
        bundle = (info as? [String: Any])?["CFBundleIdentifier"] as? String ?? ""
        var rows: [String: String] = [:]
        for line in site.components(separatedBy: "\n") where line.contains("<li><span class=\"name\">") {
            let name = line.components(separatedBy: "<span class=\"name\">")[1].components(separatedBy: "</span>")[0]
            rows[name] = line
        }
        self.rows = rows
    }

    private func escaped(_ text: String) -> String {
        text.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }

    @Test func siteListsEveryTargetOnce() {
        #expect(rows.count == Targets.allItems.count)
        for item in Targets.allItems {
            #expect(rows[escaped(item.name)] != nil, "\(item.id) is missing on the site")
        }
    }

    @Test func siteShowsWhatEachTargetRemoves() {
        for item in Targets.allItems {
            guard let row = rows[escaped(item.name)] else { continue }
            switch item.flush {
            case .removePaths:
                let shown = item.paths.map { "<span>" + escaped($0) + "</span>" }.joined()
                #expect(row.contains("<span class=\"removes\">" + shown + "</span>"), "\(item.id)")
            case .command(let command):
                #expect(row.contains("<span class=\"removes\"><span><b>$ </b>" + escaped(command) + "</span></span>"), "\(item.id)")
            }
        }
    }

    @Test func siteMarksWhatIsOffByDefault() {
        for item in Targets.allItems {
            guard let row = rows[escaped(item.name)] else { continue }
            switch item.risk {
            case .rebuilds:
                #expect(!row.contains("class=\"state\""), "\(item.id)")
            case .redownload:
                #expect(row.contains("<span class=\"state\">Off by default, slow to get back</span>"), "\(item.id)")
            case .data:
                #expect(row.contains("<span class=\"state\">Off by default, deleted for good</span>"), "\(item.id)")
            }
        }
    }

    @Test func siteListsEveryGroupWithItsCount() {
        for group in Targets.groups {
            let summary = "<span class=\"title\">\(escaped(group.name))</span><span class=\"count\">\(Messages.targets(group.items.count))</span>"
            #expect(site.contains(summary), "\(group.id)")
        }
        #expect(site.contains("<p>\(Targets.allItems.count) targets in \(Targets.groups.count) groups,"))
    }

    @Test func siteNamesThePreferencesFile() {
        #expect(bundle == "com.bircex.MacOSFlusher")
        #expect(site.contains("<code>~/Library/Preferences/\(bundle).plist</code>"))
    }

    @Test func siteNamesTheDataFile() {
        #expect(Storage.folder.path.hasSuffix("/Library/Application Support/MacOS Flusher"))
        #expect(site.contains("<code>~/Library/Application Support/MacOS Flusher/targets.json</code>"))
        #expect(site.contains("<code>~/Library/Application Support/MacOS Flusher</code>"))
    }

    @Test func siteNamesEveryAudienceInOrder() {
        let headings = site.components(separatedBy: "<h3 class=\"audience\">").dropFirst().map {
            $0.components(separatedBy: "</h3>")[0]
        }
        #expect(headings == Audience.allCases.filter { $0 != .mine }.map { escaped($0.name) })
    }
}

import Foundation
import Testing
@testable import MacOSFlusher

@Suite struct DocsTests {
    private let site: String
    private let rows: [String: String]

    init() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        site = try String(contentsOf: root.appendingPathComponent("docs/index.html"), encoding: .utf8)
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

    @Test func siteNamesEveryAudienceInOrder() {
        let headings = site.components(separatedBy: "<h3 class=\"audience\">").dropFirst().map {
            $0.components(separatedBy: "</h3>")[0]
        }
        #expect(headings == Audience.allCases.map { escaped($0.name) })
    }
}

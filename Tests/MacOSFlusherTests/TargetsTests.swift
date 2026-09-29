import Testing
@testable import MacOSFlusher

@Suite struct TargetsTests {
    @Test func idsAreUnique() {
        let ids = Targets.allItems.map(\.id)
        #expect(Set(ids).count == ids.count)
    }

    @Test func groupIdsAreUnique() {
        let ids = Targets.groups.map(\.id)
        #expect(Set(ids).count == ids.count)
    }

    @Test func noGroupIsEmpty() {
        #expect(Targets.groups.allSatisfy { !$0.items.isEmpty })
    }

    @Test func targetsThatRemovePathsHavePaths() {
        for item in Targets.allItems {
            if case .removePaths = item.flush {
                #expect(!item.paths.isEmpty, "\(item.id) removes paths but has none")
            }
        }
    }

    @Test func detailFallsBackToPaths() {
        let item = Target("sample", "Sample", ["~/a", "~/b"])
        #expect(item.detail == "~/a, ~/b")
        #expect(item.defaultOn)
    }
}

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
        #expect(item.risk == .rebuilds)
    }

    @Test func targetAndGroupIdsDoNotCollide() {
        let shared = Set(Targets.allItems.map(\.id)).intersection(Targets.groups.map(\.id))
        #expect(shared.isEmpty)
    }

    @Test func groupsOfAnAudienceStayTogether() {
        let order = Targets.groups.compactMap { Audience.allCases.firstIndex(of: $0.audience) }
        #expect(order == order.sorted())
    }

    @Test func everyAudienceHasTargets() {
        for audience in Audience.allCases {
            #expect(Targets.groups.contains { $0.audience == audience }, "\(audience) has no group")
        }
    }

    @Test func onlyWhatRebuildsStartsSelected() {
        for item in Targets.allItems {
            #expect(item.defaultOn == (item.risk == .rebuilds), "\(item.id)")
        }
    }

    @Test(arguments: [
        ("npm", Risk.rebuilds),
        ("chrome", .rebuilds),
        ("xcode-derived", .rebuilds),
        ("go-mod", .redownload),
        ("ollama", .redownload),
        ("docker-images", .redownload),
        ("trash", .data),
        ("logs", .data),
        ("docker-containers", .data),
        ("podman", .data),
        ("claude-tmp", .data),
    ])
    func riskOfKnownTargets(id: String, risk: Risk) {
        #expect(Targets.allItems.first { $0.id == id }?.risk == risk)
    }

    @Test(arguments: [
        ("chrome", "web"),
        ("spotify", "media"),
        ("trash", "system"),
        ("slack", "chat"),
        ("huggingface", "models"),
        ("ollama", "models"),
        ("pip", "python"),
    ])
    func groupOfKnownTargets(id: String, group: String) {
        #expect(Targets.groups.first { $0.items.contains { $0.id == id } }?.id == group)
    }
}

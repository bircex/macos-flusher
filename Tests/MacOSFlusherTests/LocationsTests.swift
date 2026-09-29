import Testing
@testable import MacOSFlusher

@Suite struct LocationsTests {
    private let plan = [
        DiskLocation(id: "library", name: "Library", roots: ["/Users/sample/Library"]),
        DiskLocation(id: "docker", name: "Docker", roots: ["/Users/sample/Library/Containers/com.docker.docker"]),
        DiskLocation(id: "projects", name: "~/Projects", roots: ["/Users/sample/Projects"]),
    ]

    @Test func picksTheDeepestRoot() {
        #expect(Locations.location(of: "/Users/sample/Library/Caches/pip", in: plan) == "library")
        #expect(Locations.location(of: "/Users/sample/Library/Containers/com.docker.docker/Data", in: plan) == "docker")
        #expect(Locations.location(of: "/Users/sample/Projects", in: plan) == "projects")
    }

    @Test func ignoresPathsOutsideThePlan() {
        #expect(Locations.location(of: "/Users/sample/ProjectsOld/a", in: plan) == nil)
        #expect(Locations.location(of: "/private/tmp/a", in: plan) == nil)
    }

    @Test func subtractsNestedRootsOnce() {
        let raw: [String: Int64] = [
            "/Users/sample/Library": 100,
            "/Users/sample/Library/Containers/com.docker.docker": 40,
            "/Users/sample/Library/Containers/com.docker.docker/Data/vms": 30,
            "/Users/sample/Projects": 7,
        ]
        #expect(Locations.exclusive("/Users/sample/Library", raw: raw) == 60)
        #expect(Locations.exclusive("/Users/sample/Library/Containers/com.docker.docker", raw: raw) == 10)
        #expect(Locations.exclusive("/Users/sample/Projects", raw: raw) == 7)
        #expect(Locations.exclusive("/Users/sample/Missing", raw: raw) == 0)
    }
}

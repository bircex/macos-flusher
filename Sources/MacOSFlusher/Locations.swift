import Foundation

struct DiskLocation: Identifiable, Sendable {
    let id: String
    let name: String
    let roots: [String]
    var group: String?
    var folds = false
    var other: Int64 = 0
}

struct CacheBytes {
    var selected: Int64 = 0
    var unselected: Int64 = 0

    var total: Int64 { selected + unselected }
}

struct LocationRow: Identifiable {
    let id: String
    let name: String
    var other: Int64 = 0
    var cache = CacheBytes()
    var children: [LocationRow] = []

    var total: Int64 { other + cache.total }

    mutating func add(_ row: LocationRow) {
        other += row.other
        cache.selected += row.cache.selected
        cache.unselected += row.cache.unselected
    }
}

enum Locations {
    static let dockerImage = "docker-image"
    static let foldBelow: Int64 = 1_000_000_000

    static func plan() -> [DiskLocation] {
        let home = Shell.home
        let docker = home + "/Library/Containers/com.docker.docker"
        var plan = [
            DiskLocation(id: "applications", name: "Applications", roots: ["/Applications", home + "/Applications"]),
            DiskLocation(id: dockerImage, name: "Disk image", roots: [docker + "/Data/vms"], group: "Docker"),
            DiskLocation(
                id: "docker-data",
                name: "Other Docker data",
                roots: [docker, home + "/Library/Group Containers/group.com.docker", home + "/.docker"],
                group: "Docker"
            ),
            DiskLocation(id: "library", name: "Library", roots: [home + "/Library"]),
            DiskLocation(
                id: "system",
                name: "System files",
                roots: ["/System/Applications", "/System/Library", "/System/iOSSupport", "/Library", "/private", "/usr", "/opt"]
            ),
        ]
        let fm = FileManager.default
        let taken = Set(plan.flatMap(\.roots))
        let homeVolume = volume(of: home)
        for entry in ((try? fm.contentsOfDirectory(atPath: home)) ?? []).sorted() {
            let path = home + "/" + entry
            guard !taken.contains(path), volume(of: path) == homeVolume else { continue }
            plan.append(DiskLocation(id: path, name: "~/" + entry, roots: [path], folds: true))
        }
        return plan
    }

    static func exclusive(_ root: String, raw: [String: Int64]) -> Int64 {
        let inside = raw.keys.filter { $0.hasPrefix(root + "/") }
        let nested = inside.filter { path in !inside.contains { path.hasPrefix($0 + "/") } }
        return max(0, (raw[root] ?? 0) - nested.map { raw[$0] ?? 0 }.reduce(0, +))
    }

    static func location(of path: String, in plan: [DiskLocation]) -> String? {
        plan.flatMap { location in location.roots.map { (root: $0, id: location.id) } }
            .filter { path == $0.root || path.hasPrefix($0.root + "/") }
            .max { $0.root.count < $1.root.count }?
            .id
    }

    private static func volume(of path: String) -> Int? {
        (try? FileManager.default.attributesOfItem(atPath: path))?[.systemNumber] as? Int
    }
}

extension Store {
    func cacheBytes(in plan: [DiskLocation]) -> [String: CacheBytes] {
        var caches: [String: CacheBytes] = [:]
        for item in Catalog.allItems {
            let isSelected = selected.contains(item.id)
            var found = pathSizes[item.id]?.map { (Locations.location(of: $0.key, in: plan) ?? "", $0.value) } ?? []
            if item.sizeCommand != nil, item.requires == "docker" {
                found.append((Locations.dockerImage, size(of: item) ?? 0))
            }
            for (location, bytes) in found {
                if isSelected {
                    caches[location, default: CacheBytes()].selected += bytes
                } else {
                    caches[location, default: CacheBytes()].unselected += bytes
                }
            }
        }
        return caches
    }

    var locationRows: [LocationRow] {
        guard let disk, !locations.isEmpty else { return [] }
        let caches = cacheBytes(in: locations)
        var rows: [LocationRow] = []
        var groups: [String: LocationRow] = [:]
        var rest = LocationRow(id: "home-rest", name: "Other home items")
        for location in locations {
            let row = LocationRow(
                id: location.id,
                name: location.name,
                other: location.other,
                cache: caches[location.id] ?? CacheBytes()
            )
            guard row.total > 0 else { continue }
            if let group = location.group {
                groups[group, default: LocationRow(id: group, name: group)].add(row)
                groups[group]?.children.append(row)
            } else if location.folds, row.total < Locations.foldBelow {
                rest.add(row)
            } else {
                rows.append(row)
            }
        }
        rows += groups.values.map { group in
            var sorted = group
            sorted.children.sort { $0.total > $1.total }
            return sorted
        }
        if rest.total > 0 { rows.append(rest) }
        rows.sort { $0.total > $1.total }
        let loose = caches[""] ?? CacheBytes()
        let located = rows.map(\.total).reduce(0, +)
        let unread = LocationRow(
            id: "unread",
            name: "Everything else",
            other: max(0, disk.used - located - loose.total),
            cache: loose
        )
        if unread.total > 0 { rows.append(unread) }
        return rows
    }
}

// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "MacOSFlusher",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "MacOSFlusher", targets: ["MacOSFlusher"]),
    ],
    targets: [
        .executableTarget(
            name: "MacOSFlusher",
            path: "Sources/MacOSFlusher",
            swiftSettings: [.unsafeFlags(["-swift-version", "5"])]
        ),
    ]
)

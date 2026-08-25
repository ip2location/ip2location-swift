// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "IP2LocationSwift",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        .library(name: "IP2LocationSwift", targets: ["IP2LocationSwift"]),
        .executable(name: "IP2LocationExample", targets: ["IP2LocationExample"])
    ],
    targets: [
        .target(name: "IP2LocationSwift"),
        .executableTarget(name: "IP2LocationExample", dependencies: ["IP2LocationSwift"]),
        .testTarget(name: "IP2LocationSwiftTests", dependencies: ["IP2LocationSwift"])
    ]
)

// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MumbleCore",
    platforms: [
        .iOS(.v12),
        .macOS(.v10_15)
    ],
    products: [
        // Platform-independent core library
        .library(
            name: "MumbleCore",
            targets: ["MumbleCore"]
        ),
    ],
    dependencies: [],
    targets: [
        // Core models and utilities that work on Linux
        .target(
            name: "MumbleCore",
            dependencies: [],
            path: "Sources/MumbleCore"
        ),
        // Tests for MumbleCore
        .testTarget(
            name: "MumbleCoreTests",
            dependencies: ["MumbleCore"],
            path: "Tests/MumbleCoreTests"
        ),
    ]
)

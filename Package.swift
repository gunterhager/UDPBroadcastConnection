// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "UDPBroadcast",
    platforms: [
        .iOS(.v11),
        .macOS(.v10_13),
        .tvOS(.v12),
        .watchOS(.v5)
    ],
    products: [
        .library(
            name: "UDPBroadcast",
            targets: ["UDPBroadcast"]
        ),
    ],
    targets: [
        .target(
            name: "UDPBroadcast",
            dependencies: [],
            path: "UDPBroadcast"
        ),
    ]
)

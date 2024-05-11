// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "EssentialFeed",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v12),
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "EssentialFeed",
            targets: ["EssentialFeed"]
        ),
    ],
    targets: [
        .target(
            name: "EssentialFeed"
        ),
        .testTarget(
            name: "EssentialFeedTests",
            dependencies: ["EssentialFeed"]
        ),
        .testTarget(
            name: "EssentialFeedAPIEndToEndTests",
            dependencies: ["EssentialFeed"]
        ),
        .testTarget(
            name: "EssentialFeedCacheIntegrationTests",
            dependencies: ["EssentialFeed"]
        ),
    ]
)

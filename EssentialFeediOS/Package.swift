// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "EssentialFeediOS",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "EssentialFeediOS",
            targets: ["EssentialFeediOS"]
        ),
    ],
    dependencies: [
        .package(path: "../EssentialFeed")
    ],
    targets: [
        .target(
            name: "EssentialFeediOS",
            dependencies: ["EssentialFeed"]
        ),
        .testTarget(
            name: "EssentialFeediOSTests",
            dependencies: ["EssentialFeediOS"]
        ),
    ]
)

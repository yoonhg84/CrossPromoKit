// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CrossPromoKit",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "CrossPromoKit",
            targets: ["CrossPromoKit"]
        ),
    ],
    targets: [
        .target(
            name: "CrossPromoKit",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "CrossPromoKitTests",
            dependencies: ["CrossPromoKit"]
        ),
    ]
)

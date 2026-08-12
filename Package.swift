// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CrossPromoKit",
    defaultLocalization: "en",
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
            resources: [
                .process("Resources/Localizable.xcstrings")
            ]
        ),
        .testTarget(
            name: "CrossPromoKitTests",
            dependencies: ["CrossPromoKit"]
        ),
    ]
)

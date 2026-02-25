// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "Fasting",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "FastingCore",
            targets: ["FastingCore"]
        ),
    ],
    targets: [
        .target(
            name: "FastingCore",
            path: "Sources/FastingCore"
        ),
        .testTarget(
            name: "FastingCoreTests",
            dependencies: ["FastingCore"],
            path: "Tests/FastingCoreTests"
        ),
    ]
)

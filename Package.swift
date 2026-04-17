// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "AdButlerSDK",
    platforms: [
        .iOS(.v15),
    ],
    products: [
        .library(
            name: "AdButlerSDK",
            targets: ["AdButlerSDK"]
        ),
    ],
    targets: [
        .target(
            name: "AdButlerSDK",
            path: "Sources/AdButlerSDK"
        ),
        .testTarget(
            name: "AdButlerSDKTests",
            dependencies: ["AdButlerSDK"],
            path: "Tests/AdButlerSDKTests",
            resources: [
                .process("Fixtures"),
            ]
        ),
    ]
)

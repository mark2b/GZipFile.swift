// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "GZipFile",
    platforms: [
         .macOS(.v11),
         .iOS(.v14)
    ],
    products: [
        .library(
            name: "GZipFile",
            targets: ["GZipFile"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "GZipFile",
            dependencies: [
            ]),
        .testTarget(
            name: "GZipFileTests",
            dependencies: [
                "GZipFile",
            ]),
    ]
)

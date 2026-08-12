// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "BuildTools",
    dependencies: [
        .package(url: "https://github.com/nicklockwood/SwiftFormat", exact: "0.61.1")
    ],
    targets: [
        .target(name: "BuildTools", path: "")
    ]
)

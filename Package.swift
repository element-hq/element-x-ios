// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Element Swift",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "tools", targets: ["Tools"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", .upToNextMinor(from: "1.7.0")),
        .package(url: "https://github.com/element-hq/swift-command-line-tools.git", revision: "e5eaab1558ef664e6cd80493f64259381670fb3a"),
        // .package(path: "../../../swift-command-line-tools"),
        .package(url: "https://github.com/jpsim/Yams", .upToNextMinor(from: "6.2.0"))
    ],
    targets: [
        .executableTarget(name: "Tools",
                          dependencies: [
                            .product(name: "ArgumentParser", package: "swift-argument-parser"),
                            .product(name: "CommandLineTools", package: "swift-command-line-tools"),
                            .product(name: "Yams", package: "Yams")
                          ],
                          path: "Tools/Sources")
    ]
)

// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Element Swift",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "tools", targets: ["Tools"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.0"),
        .package(url: "https://github.com/jpsim/Yams", from: "5.0.1")
    ],
    targets: [
        .executableTarget(name: "Tools",
                          dependencies: [
                              .product(name: "ArgumentParser", package: "swift-argument-parser"),
                              .product(name: "Yams", package: "Yams")
                          ],
                          path: "Tools/Sources")
    ]
)

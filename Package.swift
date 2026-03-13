// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import Foundation

var dependencies: [Package.Dependency] = [
    .package(url: "https://github.com/apple/swift-argument-parser", .upToNextMinor(from: "1.7.0")),
    .package(url: "https://github.com/element-hq/swift-command-line-tools.git", branch: "main"),
    // .package(path: "../../../swift-command-line-tools"),
    .package(url: "https://github.com/swiftlang/swift-subprocess", .upToNextMinor(from: "0.3.0")),
    .package(url: "https://github.com/jpsim/Yams", .upToNextMinor(from: "6.2.1")),
    .package(url: "https://github.com/apple/swift-log", .upToNextMinor(from: "1.10.1"))
]

if FileManager.default.fileExists(atPath: "Enterprise/Pipeline/Package.swift") {
    dependencies.append(.package(path: "./enterprise/pipeline"))
}

let package = Package(
    name: "Element Swift",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "tools", targets: ["Tools"])
    ],
    dependencies: dependencies,
    targets: [
        .executableTarget(name: "Tools",
                          dependencies: [
                            .product(name: "ArgumentParser", package: "swift-argument-parser"),
                            .product(name: "CommandLineTools", package: "swift-command-line-tools"),
                            .product(name: "Subprocess", package: "swift-subprocess"),
                            .product(name: "Yams", package: "Yams"),
                            .product(name: "Logging", package: "swift-log")
                          ],
                          path: "Tools/Sources")
    ]
)

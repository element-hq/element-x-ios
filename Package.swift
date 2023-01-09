// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Element Swift",
    platforms: [
        .iOS(.v14),
        .macOS(.v13)
    ],
    products: [
        .library(name: "DesignKit", targets: ["DesignKit"]),
        .executable(name: "tools", targets: ["Tools"])
    ],
    dependencies: [
        .package(url: "https://github.com/vector-im/element-design-tokens.git", exact: "0.0.3"),
        .package(url: "https://github.com/siteline/SwiftUI-Introspect.git", from: "0.1.4"),
        /* Command line tools dependencies */
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.0"),
        .package(url: "https://github.com/jpsim/Yams", from: "5.0.1"),
        /* Package plug-ins */
        .package(url: "https://github.com/realm/SwiftLint", branch: "main"),
        .package(url: "https://github.com/nicklockwood/SwiftFormat", from: "0.50.4")
    ],
    targets: [
        .target(name: "DesignKit",
                dependencies: [
                    .product(name: "DesignTokens", package: "element-design-tokens"),
                    .product(name: "Introspect", package: "SwiftUI-Introspect")
                ],
                path: "DesignKit"),
        .testTarget(name: "DesignKitTests",
                    dependencies: ["DesignKit"],
                    path: "DesignKitTests"),
        .executableTarget(name: "Tools",
                          dependencies: [
                              .product(name: "ArgumentParser", package: "swift-argument-parser"),
                              .product(name: "Yams", package: "Yams")
                          ],
                          path: "Tools/Sources"),
        .plugin(name: "SwiftLint",
                capability: .command(intent: .custom(verb: "swiftlint", description: "Run swiftlint on the project directory")),
                dependencies: [
                    .product(name: "swiftlint", package: "SwiftLint")
                ],
                path: "Tools/Plugins/SwiftLint")
    ]
)

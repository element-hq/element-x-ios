// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DesignKit",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(name: "DesignKit", targets: ["DesignKit"])
    ],
    dependencies: [
        .package(url: "https://github.com/vector-im/compound-ios", revision: "38bbcdd6104a6b07489619996f39b3aa003d9dc5"),
        .package(url: "https://github.com/vector-im/element-design-tokens", exact: "0.0.3"),
        .package(url: "https://github.com/siteline/SwiftUI-Introspect", from: "0.9.0")
    ],
    targets: [
        .target(name: "DesignKit",
                dependencies: [
                    .product(name: "Compound", package: "compound-ios"),
                    .product(name: "DesignTokens", package: "element-design-tokens"),
                    .product(name: "SwiftUIIntrospect", package: "SwiftUI-Introspect")
                ],
                path: "Sources"),
        .testTarget(name: "DesignKitTests",
                    dependencies: ["DesignKit"],
                    path: "Tests")
    ]
)

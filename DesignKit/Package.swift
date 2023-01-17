// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DesignKit",
    platforms: [
        .iOS(.v14),
    ],
    products: [
        .library(name: "DesignKit", targets: ["DesignKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vector-im/element-design-tokens.git", exact: "0.0.3"),
        .package(url: "https://github.com/siteline/SwiftUI-Introspect.git", from: "0.1.4"),
    ],
    targets: [
        .target(name: "DesignKit",
                dependencies: [
                    .product(name: "DesignTokens", package: "element-design-tokens"),
                    .product(name: "Introspect", package: "SwiftUI-Introspect")
                ],
                path: "Sources"),
        .testTarget(name: "DesignKitTests",
                    dependencies: ["DesignKit"],
                    path: "Tests"),
    ]
)

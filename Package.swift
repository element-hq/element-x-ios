// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DesignKit",
    platforms: [.iOS(.v14)],
    products: [
        .library(name: "DesignKit", targets: ["DesignKit"])
    ],
    dependencies: [.package(url: "https://github.com/siteline/SwiftUI-Introspect.git", .upToNextMajor(from: "0.1.4"))],
    targets: [
        .target(name: "DesignKit",
                dependencies: [.product(name: "Introspect", package: "SwiftUI-Introspect")],
                path: "DesignKit"),
        .testTarget(name: "DesignKitTests",
                    dependencies: ["DesignKit"],
                    path: "DesignKitTests")
    ]
)

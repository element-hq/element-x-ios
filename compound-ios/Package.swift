// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Compound",
    platforms: [.iOS(.v18)],
    products: [
        .library(name: "Compound", targets: ["Compound"])
    ],
    dependencies: [
<<<<<<< HEAD
// Use the Github hosted version of Tchap Compound-design--tokens
//      .package(url: "https://github.com/element-hq/compound-design-tokens", exact: "10.2.3"),
        .package(url: "https://github.com/tchapgouv/compound-design-tokens", revision: "a19aa264c6f3e063d265213f06804c2dfe2a7884"),
// Use the local version of Tchap Compound-design--tokens
//        .package(path: "../../tchap-x-compound/compound-design-tokens"),
        .package(url: "https://github.com/siteline/SwiftUI-Introspect", from: "26.0.1"),
        .package(url: "https://github.com/SFSafeSymbols/SFSafeSymbols", from: "7.0.0"),
=======
        .package(url: "https://github.com/element-hq/compound-design-tokens", exact: "11.0.0"),
        // .package(path: "../../compound-design-tokens"),
        .package(url: "https://github.com/siteline/SwiftUI-Introspect", exact: "27.0.0"),
        .package(url: "https://github.com/SFSafeSymbols/SFSafeSymbols", exact: "7.0.0"),
>>>>>>> release/26.09.2
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", exact: "1.19.4")
    ],
    targets: [
        .target(
            name: "Compound",
            dependencies: [
                .product(name: "CompoundDesignTokens", package: "compound-design-tokens"),
                .product(name: "SwiftUIIntrospect", package: "SwiftUI-Introspect"),
                .product(name: "SFSafeSymbols", package: "SFSafeSymbols")
            ],
            swiftSettings: [
                .defaultIsolation(MainActor.self)
            ]
        ),
        .testTarget(
            name: "CompoundTests",
            dependencies: [
                "Compound",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
            ],
            exclude: [
                "__Snapshots__"
            ],
            swiftSettings: [
                .defaultIsolation(MainActor.self)
            ]
        )
    ]
)

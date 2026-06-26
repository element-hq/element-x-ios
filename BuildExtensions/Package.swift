// swift-tools-version: 6.2

import CompilerPluginSupport
import PackageDescription

let package = Package(
    name: "BuildExtensions",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "Macros", targets: ["Macros"])
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax", from: "602.0.0")
    ],
    targets: [
        // The public macro declarations imported by the app.
        .target(name: "Macros",
                dependencies: ["MacrosImplementation"],
                swiftSettings: [
                    .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
                    .enableUpcomingFeature("InferIsolatedConformances")
                ]),
        // The compiler plugin holding the SwiftSyntax expansions.
        .macro(name: "MacrosImplementation",
               dependencies: [
                   .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                   .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
               ],
               swiftSettings: [
                    .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
                    .enableUpcomingFeature("InferIsolatedConformances")
               ]),
        .testTarget(name: "MacrosTests",
                    dependencies: [
                        "MacrosImplementation",
                        .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax")
                    ],
                    swiftSettings: [
                        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
                        .enableUpcomingFeature("InferIsolatedConformances")
                    ])
    ]
)

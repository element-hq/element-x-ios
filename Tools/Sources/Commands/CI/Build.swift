//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import ArgumentParser
import Foundation

struct Build: AsyncParsableCommand {
    static let configuration = CommandConfiguration(commandName: "build",
                                                    abstract: "Builds a scheme for testing without running tests.",
                                                    discussion: """
                                                    Runs xcodebuild build-for-testing and archives the build products so they
                                                    can be shared across multiple test jobs via CI artifacts.
                                                    """)

    @Option(help: "The Xcode scheme to build.")
    var scheme: String

    @Option(help: "Device name for the destination.")
    var device = "iPhone 17"

    @Option(help: "iOS version for the simulator.")
    var osVersion = "26.1"

    @Option(help: "DerivedData path for the build output.")
    var derivedDataPath = "DerivedData"

    func run() async throws {
        logger.info("\n🔨 Building \(scheme) for testing…\n")

        var command = "set -o pipefail && xcodebuild build-for-testing"
        command += " -scheme \(scheme)"
        command += " -sdk iphonesimulator"
        command += " -destination 'platform=iOS Simulator,name=\(device),OS=\(osVersion)'"
        command += " -derivedDataPath \(derivedDataPath)"
        command += " -skipPackagePluginValidation"
        command += " | xcbeautify"

        try await CI.run(.path("/bin/zsh"), ["-cu", command])

        logger.info("\n✅ Build complete.\n")
    }
}

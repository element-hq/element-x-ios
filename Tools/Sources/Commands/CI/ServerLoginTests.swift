//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import ArgumentParser
import Foundation

struct ServerLoginTests: AsyncParsableCommand {
    static let configuration = CommandConfiguration(commandName: "server-login-tests",
                                                    abstract: "Runs the server login integration test CI workflow.",
                                                    discussion: """
                                                    Runs a login test against an arbitrary server using INTEGRATION_TESTS_HOST/
                                                    USERNAME/PASSWORD. Designed to be driven by a CI matrix so credentials
                                                    for each server are injected at runtime.
                                                    """)

    @Option(help: "Device name for tests.")
    var device = "iPhone 17"
    
    @Option(help: "iOS version for the simulator.")
    var osVersion = "26.1"
    
    func run() async throws {
        // Delete old log files
        logger.info("🗑️ Deleting old log files…")
        try await CI.run(.path("/bin/zsh"), ["-cu", "find '/Users/Shared' -name 'console*' -delete"])
        
        var testsFailed = false
        do {
            logger.info("\n🧪 Running server login integration tests…\n")
            try await RunTests.parse([
                "--scheme", "IntegrationTests",
                "--device", device,
                "--os-version", osVersion,
                "--retries", "0",
                "--test-name", "ServerLoginTests"
            ]).run()
        } catch {
            testsFailed = true
            logger.error("\n❌ Server login integration tests failed.\n")
        }
        
        // Validate logs only when tests passed — log files won't be meaningful otherwise
        if !testsFailed {
            do {
                logger.info("🔍 Checking logs are set to the trace level…")
                try await CI.run(.path("/bin/zsh"), ["-cu", "grep ' TRACE ' /Users/Shared -qR"])
                logger.info("✅ Trace level logging verified.")
            } catch {
                testsFailed = true
                logger.error("❌ Logs are not set to the trace level.")
            }
        }
        
        await CI.zipResults(bundles: ["IntegrationTests.xcresult"],
                            outputName: "IntegrationTests.xcresult.zip")
        
        await CI.collectCoverage(resultBundle: "IntegrationTests.xcresult", outputName: "server-login-cobertura.xml")
        await CI.collectTestResults(resultBundle: "IntegrationTests.xcresult", outputName: "server-login-junit.xml")
        
        if testsFailed {
            throw ExitCode.failure
        }
        
        logger.info("\n✅ Server login integration tests passed.\n")
    }
}

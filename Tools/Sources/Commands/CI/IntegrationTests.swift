import ArgumentParser
import Foundation

struct IntegrationTests: AsyncParsableCommand {
    static let configuration = CommandConfiguration(commandName: "integration-tests",
                                                    abstract: "Runs the integration test CI workflow.",
                                                    discussion: """
                                                    Deletes old log files, runs integration tests, validates that logs are set
                                                    to the trace level and don't contain private messages, then collects results.
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
            logger.info("\n🧪 Running integration tests…\n")
            try await RunTests.parse([
                "--scheme", "IntegrationTests",
                "--device", device,
                "--os-version", osVersion,
                "--retries", "0"
            ]).run()
        } catch {
            testsFailed = true
            logger.error("\n❌ Integration tests failed.\n")
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
            
            do {
                logger.info("🔍 Checking logs don't contain private messages…")
                try await CI.run(.path("/bin/zsh"), ["-cu", "! grep 'Go down in flames' /Users/Shared -R"])
                logger.info("✅ No private messages found in logs.")
            } catch {
                testsFailed = true
                logger.error("❌ Private messages found in logs.")
            }
        }
        
        await CI.zipResults(bundles: ["IntegrationTests.xcresult"],
                            outputName: "IntegrationTests.xcresult.zip")
        
        await CI.collectCoverage(resultBundle: "IntegrationTests.xcresult", outputName: "integration-cobertura.xml")
        await CI.collectTestResults(resultBundle: "IntegrationTests.xcresult", outputName: "integration-junit.xml")
        
        if testsFailed {
            throw ExitCode.failure
        }
        
        logger.info("\n✅ Accessibility tests passed.\n")
    }
}

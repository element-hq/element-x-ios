import ArgumentParser
import CommandLineTools
import Foundation

struct AccessibilityTests: AsyncParsableCommand {
    static let configuration = CommandConfiguration(commandName: "accessibility-tests",
                                                    abstract: "Runs the accessibility test CI workflow.")

    @Option(help: "Device name for tests.")
    var device = "iPhone 17"
    
    @Option(help: "iOS version for the simulator.")
    var osVersion = "26.1"
    
    func run() async throws {
        var testsFailed = false
        do {
            logger.info("\n🧪 Running accessibility tests…\n")
            try await RunTests.parse([
                "--scheme", "AccessibilityTests",
                "--device", device,
                "--os-version", osVersion,
                "--retries", "0"
            ]).run()
        } catch {
            testsFailed = true
            logger.error("\n❌ Accessibility tests failed.\n")
        }

        // Zip results (best-effort, useful for CI artifact uploads)
        await CI.zipResults(bundles: ["AccessibilityTests.xcresult"],
                            outputName: "AccessibilityTests.xcresult.zip")

        if testsFailed {
            throw ExitCode.failure
        }

        logger.info("\n✅ Accessibility tests passed.\n")
    }
}

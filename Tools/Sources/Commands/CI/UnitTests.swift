import ArgumentParser
import CommandLineTools
import Foundation

struct UnitTests: AsyncParsableCommand {
    static let configuration = CommandConfiguration(commandName: "unit-tests",
                                                    abstract: "Runs the unit test CI workflow: lint, unit tests, preview tests, and result collection.")
    
    @Option(help: "Device name for unit tests.")
    var device = "iPhone 17"
    
    @Option(help: "iOS version for the simulator.")
    var osVersion = "26.1"
    
    func run() async throws {
        try await CI.lint()
        
        var failures: [String] = []
        
        // Run unit tests
        do {
            logger.info("\n🧪 Running unit tests…\n")
            try await RunTests.parse([
                "--scheme", "UnitTests",
                "--device", device,
                "--os-version", osVersion,
                "--retries", "3"
            ]).run()
        } catch {
            failures.append("Unit tests failed: \(error)")
            logger.error("\n❌ Unit tests failed. \(error)\n")
        }
        
        // Run preview tests on a smaller device
        do {
            logger.info("\n🧪 Running preview tests…")
            try await RunTests.parse([
                "--scheme", "PreviewTests",
                "--device", "iPhone SE (3rd generation)",
                "--os-version", osVersion,
                "--create-simulator-name", "iPhone SE (3rd generation)",
                "--create-simulator-type", "com.apple.CoreSimulator.SimDeviceType.iPhone-SE-3rd-generation"
            ]).run()
        } catch {
            failures.append("Preview tests failed: \(error)")
            logger.error("\n❌ Preview tests failed.\n")
        }
        
        // Zip results (best-effort, useful for CI artifact uploads)
        await CI.zipResults(bundles: ["UnitTests.xcresult", "PreviewTests.xcresult"],
                            outputName: "UnitTests.zip")
        
        // Collect coverage reports
        await CI.collectCoverage(resultBundle: "UnitTests.xcresult", outputName: "unit-cobertura.xml")
        await CI.collectCoverage(resultBundle: "PreviewTests.xcresult", outputName: "preview-cobertura.xml")
        
        // Collect JUnit test results
        await CI.collectTestResults(resultBundle: "UnitTests.xcresult", outputName: "unit-junit.xml")
        await CI.collectTestResults(resultBundle: "PreviewTests.xcresult", outputName: "preview-junit.xml")
        
        if !failures.isEmpty {
            logger.error("\n❌ \(failures.count) test suite(s) failed.\n")
            throw ExitCode.failure
        }
        
        logger.info("\n✅ All unit test suites passed.\n")
    }
}

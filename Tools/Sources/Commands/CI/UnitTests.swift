import ArgumentParser
import Foundation

struct UnitTests: AsyncParsableCommand {
    static let configuration = CommandConfiguration(commandName: "unit-tests",
                                                    abstract: "Runs the unit test CI workflow: lint, unit tests, preview tests, and result collection.")
    
    @Flag(help: "Skip preview tests")
    var skipPreviews = false
    
    @Flag(help: "Run the unit tests on a saturated CPU to reproduce the flakiness of a busy CI runner.")
    var constrained = false
    
    private static let osVersion = CI.defaultOSVersion
    private static let device = "iPhone 17"
    
    func run() async throws {
        try await CI.lint()
        
        var failures: [String] = []
        
        // Run unit tests
        do {
            logger.info("\n🧪 Running unit tests…\n")
            
            var arguments = [
                "--scheme", "UnitTests",
                "--device", Self.device,
                "--os-version", Self.osVersion,
                "--retries", "3"
            ]
            if constrained {
                arguments.append("--constrained")
            }
            
            try await RunTests.parse(arguments).run()
        } catch {
            failures.append("UnitTests")
            logger.error("\n❌ Unit tests failed. \(error)\n")
        }
        
        if !skipPreviews {
            do {
                try await PreviewTests.parse([]).run()
            } catch {
                failures.append("PreviewTests")
                logger.error("\n❌ Preview tests failed. \(error)\n")
            }
        }
        
        // Zip results (best-effort, useful for CI artifact uploads)
        await CI.zipResults(bundles: ["UnitTests.xcresult", "PreviewTests.xcresult"],
                            outputName: "UnitTests.zip")
        
        // Collect coverage and JUnit results for unit tests
        await CI.collectCoverage(resultBundle: "UnitTests.xcresult", outputName: "unit-cobertura.xml")
        await CI.collectTestResults(resultBundle: "UnitTests.xcresult", outputName: "unit-junit.xml")
        
        if !failures.isEmpty {
            let failedSuites = "[\(failures.joined(separator: ","))]"
            logger.error("\n❌ \(failures.count) test suite(s) failed \(failedSuites)\n")
            throw ExitCode.failure
        }
        
        logger.info("\n✅ All unit test suites passed.\n")
    }
}

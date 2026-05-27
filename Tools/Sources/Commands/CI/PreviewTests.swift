import ArgumentParser
import Foundation

struct PreviewTests: AsyncParsableCommand {
    static let configuration = CommandConfiguration(commandName: "preview-tests",
                                                    abstract: "Runs the preview test CI workflow, with optional snapshot recording.")
    
    @Flag(help: "Re-record snapshots for tests that fail or are missing a reference image.")
    var record = false
    
    private static let scheme = "PreviewTests"
    private static let device = "iPhone SE (3rd generation)"
    private static let osVersion = "26.4.1"
    private static let simulatorType = "com.apple.CoreSimulator.SimDeviceType.iPhone-SE-3rd-generation"
    private static let testPlanPath = "PreviewTests/SupportingFiles/PreviewTests.xctestplan"
    
    func run() async throws {
        if record {
            try setRecordFailures(enabled: true)
        }
        
        var testsFailed = false
        do {
            logger.info("\n🧪 Running preview tests…\n")
            try await RunTests.parse([
                "--scheme", Self.scheme,
                "--device", Self.device,
                "--os-version", Self.osVersion,
                "--create-simulator-name", Self.device,
                "--create-simulator-type", Self.simulatorType
            ]).run()
        } catch {
            if record {
                // In recording mode, test failures are expected — swift-snapshot-testing marks
                // recording runs as failed. Check whether the xcresult bundle was created to
                // distinguish genuine failures (compilation error, simulator issue) from the
                // expected snapshot-recording "failures".
                let resultBundleURL = URL.projectDirectory
                    .appending(path: "\(CI.testOutputDirectory)/\(Self.scheme).xcresult")
                guard FileManager.default.fileExists(atPath: resultBundleURL.path) else {
                    logger.error("\n❌ Preview tests could not run. Check for compilation or configuration errors.\n")
                    throw error
                }
                logger.info("\n📸 Snapshots recorded.\n")
            } else {
                logger.error("\n❌ Preview tests failed.\n")
                testsFailed = true
            }
        }
        
        // Collect coverage and test results regardless of test outcome (best-effort).
        await CI.collectCoverage(resultBundle: "\(Self.scheme).xcresult", outputName: "preview-cobertura.xml")
        await CI.collectTestResults(resultBundle: "\(Self.scheme).xcresult", outputName: "preview-junit.xml")
        
        if testsFailed {
            throw ExitCode.failure
        }
        
        if !record {
            logger.info("\n✅ Preview tests passed.\n")
        }
    }
    
    // MARK: - Test Plan
    
    /// Enables or disables the `RECORD_FAILURES` environment variable entry in the test plan.
    private func setRecordFailures(enabled: Bool) throws {
        let url = URL.projectDirectory.appendingPathComponent(Self.testPlanPath)
        let data = try Data(contentsOf: url)
        
        guard var plan = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              var defaultOptions = plan["defaultOptions"] as? [String: Any],
              var envVars = defaultOptions["environmentVariableEntries"] as? [[String: Any]] else {
            throw ValidationError("Could not parse test plan at \(Self.testPlanPath).")
        }
        
        for index in envVars.indices where envVars[index]["key"] as? String == "RECORD_FAILURES" {
            envVars[index]["enabled"] = enabled
            break
        }
        
        defaultOptions["environmentVariableEntries"] = envVars
        plan["defaultOptions"] = defaultOptions
        
        let jsonData = try JSONSerialization.data(withJSONObject: plan, options: [.prettyPrinted, .sortedKeys])
        try jsonData.write(to: url)
    }
}

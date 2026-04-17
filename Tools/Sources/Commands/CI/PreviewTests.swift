import ArgumentParser
import Foundation

struct PreviewTests: AsyncParsableCommand {
    static let configuration = CommandConfiguration(commandName: "preview-tests",
                                                    abstract: "Runs the preview test CI workflow.")

    @Option(help: "iOS version for the simulator.")
    var osVersion = "26.4"

    private static let scheme = "PreviewTests"
    private static let device = "iPhone SE (3rd generation)"
    private static let simulatorType = "com.apple.CoreSimulator.SimDeviceType.iPhone-SE-3rd-generation"
    private static let testPlanPath = "PreviewTests/SupportingFiles/PreviewTests.xctestplan"

    func run() async throws {
        var testsFailed = false
        do {
            logger.info("\n🧪 Running preview tests…\n")
            try await RunTests.parse([
                "--scheme", Self.scheme,
                "--device", Self.device,
                "--os-version", osVersion,
                "--create-simulator-name", Self.device,
                "--create-simulator-type", Self.simulatorType
            ]).run()
        } catch {
            logger.error("\n❌ Preview tests failed.\n")
            testsFailed = true
        }

        // Collect coverage and test results regardless of test outcome (best-effort).
        await CI.collectCoverage(resultBundle: "\(Self.scheme).xcresult", outputName: "preview-cobertura.xml")
        await CI.collectTestResults(resultBundle: "\(Self.scheme).xcresult", outputName: "preview-junit.xml")

        if testsFailed {
            throw ExitCode.failure
        }

        logger.info("\n✅ Preview tests passed.\n")
    }
}

import ArgumentParser
import CommandLineTools
import Foundation
import Subprocess

struct RunTests: AsyncParsableCommand {
    static let configuration = CommandConfiguration(abstract: "Runs xcodebuild tests with simulator management, retries, and formatting.",
                                                    discussion: """
                                                    Uses xcodebuild's native -retry-tests-on-failure flag to retry only \
                                                    failing tests instead of re-running the entire suite.
                                                    
                                                    Examples:
                                                      swift run tools run-tests --scheme UnitTests
                                                      swift run tools run-tests --scheme UITests --device iPhone --os-version 26.1
                                                      swift run tools run-tests --scheme PreviewTests --create-simulator-name "iPhone SE (3rd generation)" \
                                                        --create-simulator-type com.apple.CoreSimulator.SimDeviceType.iPhone-SE-3rd-generation
                                                    """)

    @Option(help: "The Xcode scheme to test.")
    var scheme: String

    @Option(help: "The simulator device name to run tests on (e.g. 'iPhone 17').")
    var device = "iPhone 17"

    @Option(help: "The iOS version to use for the simulator runtime (e.g. '26.1').")
    var osVersion = "26.1"

    @Option(help:
        "Number of times to retry failed tests. Only the failing tests are re-run, not the entire suite.")
    var retries = 3

    @Option(help: "When set, create a simulator with this name if one doesn't already exist.")
    var createSimulatorName: String?

    @Option(help:
        "The simulator device type identifier for creating a new simulator (e.g. 'com.apple.CoreSimulator.SimDeviceType.iPhone-SE-3rd-generation').")
    var createSimulatorType: String?

    @Option(help: "Only run a specific test (format: 'ClassName/testName').")
    var testName: String?

    private var isCI: Bool {
        ProcessInfo.processInfo.environment["CI"] != nil
    }
    
    private var resultBundlePath: String {
        "test_output/\(scheme).xcresult"
    }
    
    private var formatter: String {
        "xcbeautify -q --disable-logging --is-ci --renderer github-actions"
    }

    private var simulatorRuntime: String {
        "com.apple.CoreSimulator.SimRuntime.iOS-\(osVersion.replacingOccurrences(of: ".", with: "-"))"
    }

    func run() async throws {
        if let createName = createSimulatorName {
            guard let createType = createSimulatorType else {
                throw ValidationError("--create-simulator-type must be provided when --create-simulator-name is set.")
            }
            try await createSimulatorIfNecessary(name: createName, type: createType)
        }
        
        // Remove any previous result bundle at this path
        let resultBundleURL = URL.projectDirectory.appendingPathComponent(resultBundlePath)
        if FileManager.default.fileExists(atPath: resultBundleURL.path) {
            try? FileManager.default.removeItem(at: resultBundleURL)
        }

        // Ensure the output directory exists
        let outputDirectory = resultBundleURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

        try await executeXcodeBuild()
        
        try await shutdownSimulator()

        logger.info("\n✅ Tests passed.\n")
    }

    // MARK: - Simulator Management
    
    private func createSimulatorIfNecessary(name: String, type: String) async throws {
        logger.info("Checking for simulator '\(name)'…")
        
        guard let simulators = try await CI.run(.path("/bin/zsh"), ["-cu", "xcrun simctl list devices \"iOS \(osVersion)\" available"],
                                                output: .string(limit: 4096)).standardOutput else {
            logger.info("No simulators found for iOS \(osVersion). Creating '\(name)'…")
            try await createSimulator(name: name, type: type)
            return
        }
        
        // Use a `(` to avoid matching e.g. "iPhone 14 Pro" on "iPhone 14 Pro Max"
        let hasExisting = simulators.components(separatedBy: "\n").contains { line in
            line.contains("\(name) (")
        }

        if hasExisting {
            logger.info("Simulator '\(name)' already exists.")
        } else {
            logger.info("Simulator '\(name)' not found. Creating…")
            try await createSimulator(name: name, type: type)
        }
    }
    
    private func createSimulator(name: String, type: String) async throws {
        let deviceID = try await CI.run(.path("/bin/zsh"), ["-cu", "xcrun simctl create '\(name)' \(type) \(simulatorRuntime)"],
                                        output: .string(limit: 4096)).standardOutput
        logger.info("Created simulator '\(name)' (\(deviceID?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "unknown")).")
    }
    
    // MARK: - Simulator Shutdown
    
    private func shutdownSimulator() async throws {
        print("Shutting down simulator '\(device)'…")
        
        let command = "xcrun simctl shutdown '\(device)' 2>/dev/null || true"
        _ = try await CI.run(.path("/bin/zsh"), ["-cu", command])
        
        print("Simulator shut down.")
    }
    
    // MARK: - Test Running

    private func executeXcodeBuild() async throws {
        var command = "set -o pipefail && xcodebuild test"
        command += " -scheme \(scheme)"
        command += " -sdk iphonesimulator"
        command +=
            " -destination 'platform=iOS Simulator,name=\(device),OS=\(osVersion),arch=arm64'"
        command += " -resultBundlePath \(resultBundlePath)"
        command += " -skipPackagePluginValidation"

        // Use xcodebuild's native retry support to re-run only failing tests
        // instead of re-running the entire suite. retries=0 means no retries (single run).
        if retries > 0 {
            // -test-iterations is the total number of attempts (initial + retries)
            command += " -retry-tests-on-failure"
            command += " -test-iterations \(retries + 1)"
        }

        if let testName {
            command += " -only-testing:\(scheme)/\(testName)"
        }

        command += " | \(formatter)"

        _ = try await CI.run(.path("/bin/zsh"), ["-cu", command])
    }
}

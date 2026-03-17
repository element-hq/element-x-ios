import ArgumentParser
import Foundation
import Subprocess
import Yams

struct CI: ParsableCommand {
    static let configuration = CommandConfiguration(abstract: "CI workflow commands that can be run both locally and in CI environments.",
                                                    subcommands: [
                                                        AccessibilityTests.self,
                                                        UnitTests.self,
                                                        UITests.self,
                                                        IntegrationTests.self,
                                                        RunTests.self,
                                                        ConfigureNightly.self,
                                                        ConfigureProduction.self,
                                                        TagNightly.self,
                                                        UploadDSYMs.self,
                                                        ReleaseToGitHub.self
                                                    ])
    
    static let testOutputDirectory = "test_output"
    
    /// Reads the `MARKETING_VERSION` from `project.yml`.
    static func readMarketingVersion() throws -> String {
        let projectURL = URL.projectDirectory.appending(component: "project.yml")
        let projectString = try String(contentsOf: projectURL)
        
        guard let projectConfig = try Yams.compose(yaml: projectString),
              let version = projectConfig["settings"]?["MARKETING_VERSION"]?.string else {
            throw ValidationError("Could not find MARKETING_VERSION in project.yml.")
        }
        
        return version
    }
    
    // MARK: - Linting
    
    /// Runs SwiftFormat in lint mode against the current directory.
    static func lint() async throws {
        logger.info("\n🔍 Running SwiftFormat lint…\n")
        
        do {
            try await run(.name("swiftformat"), ["--lint", "."])
        } catch {
            logger.error("\n❌ SwiftFormat failed.\n")
            throw error
        }
        logger.info("\n✅ SwiftFormat passed.\n")
    }
    
    // MARK: - Test Results
    
    /// Collects coverage from an xcresult bundle using xcresultparser (cobertura format).
    /// Failures are non-fatal — the output file simply won't be created.
    static func collectCoverage(resultBundle: String, target: String = "ElementX", outputName: String) async {
        let projectPath = URL.projectDirectory.path
        let resultBundlePath = "\(testOutputDirectory)/\(resultBundle)"
        let outputPath = "\(testOutputDirectory)/\(outputName)"
        
        guard FileManager.default.fileExists(atPath: resultBundlePath) else {
            logger.error("\n❌ Result bundle not found at \(resultBundlePath), skipping coverage collection.\n")
            return
        }
        
        do {
            try await run(.path("/bin/zsh"), ["-cu", "xcresultparser -q -o cobertura -t \(target) -p \(projectPath) \(resultBundlePath) > \(outputPath)"])
            logger.info("\n📊 Coverage report: \(outputPath)\n")
        } catch {
            logger.error("\n❌ Failed to collect coverage for \(resultBundle): \(error.localizedDescription)\n")
        }
    }
    
    /// Collects test results from an xcresult bundle using xcresultparser (junit format).
    /// Failures are non-fatal — the output file simply won't be created.
    static func collectTestResults(resultBundle: String, outputName: String) async {
        let projectPath = URL.projectDirectory.path
        let resultBundlePath = "\(testOutputDirectory)/\(resultBundle)"
        let outputPath = "\(testOutputDirectory)/\(outputName)"
        
        guard FileManager.default.fileExists(atPath: resultBundlePath) else {
            logger.info(" Result bundle not found at \(resultBundlePath), skipping test result collection.")
            return
        }
        
        do {
            try await run(.path("/bin/zsh"), ["-cu", "xcresultparser -q -o junit -p \(projectPath) \(resultBundlePath) > \(outputPath)"])
            logger.info("📋 Test results: \(outputPath)")
        } catch {
            logger.error("\n❌ Failed to collect test results for \(resultBundle): \(error.localizedDescription)\n")
        }
    }
    
    /// Zips xcresult bundles in the test output directory for faster artifact uploads.
    static func zipResults(bundles: [String], outputName: String) async {
        let bundleArgs = bundles.joined(separator: " ")
        do {
            logger.info("\n📦 Zipping test results…")
            try await run(.path("/bin/zsh"), ["-cu", "cd \(testOutputDirectory) && zip -rq \(outputName) \(bundleArgs)"])
            logger.info("📦 Zipped: \(testOutputDirectory)/\(outputName)\n")
        } catch {
            logger.error("\n❌ Failed to zip results: \(error.localizedDescription)\n")
        }
    }
    
    // MARK: - Shell Interaction
    
    @discardableResult
    static func run<Output: OutputProtocol, Error: ErrorOutputProtocol>(_ executable: Executable,
                                                                        _ arguments: Arguments = [],
                                                                        environment: Environment = .inherit,
                                                                        output: Output = .standardOutput,
                                                                        error: Error = .standardError) async throws -> CollectedResult<Output, Error> {
        logger.info("Running \(executable), with arguments: \(arguments)")
        
        let result = try await Subprocess.run(executable,
                                              arguments: arguments,
                                              environment: environment,
                                              output: output,
                                              error: error)
        
        if case let .exited(code) = result.terminationStatus, code != 0 {
            throw ExitCode.failure
        }
        
        return result
    }
    
    // MARK: - Git
    
    static func gitConfigureGlobals() async throws {
        guard let apiToken = ProcessInfo.processInfo.environment["GITHUB_TOKEN"], !apiToken.isEmpty else {
            throw ValidationError("GITHUB_TOKEN environment variable is not set.")
        }

        try await CI.run(.name("git"), ["config", "--global", "user.name", "Element CI"])
        try await CI.run(.name("git"), ["config", "--global", "user.email", "ci@element.io"])
        try await CI.run(.name("git"), ["config", "--global", "http.extraHeader", "Authorization: Bearer \(apiToken)"])
    }
    
    static func gitRepositoryURL() async throws -> String {
        guard let rawURL = try await CI.run(.name("git"), ["ls-remote", "--get-url", "origin"],
                                            output: .string(limit: 4096)).standardOutput else {
            throw ValidationError("Could not determine the git remote URL.")
        }
        
        return rawURL
            .replacingOccurrences(of: "http://", with: "")
            .replacingOccurrences(of: "https://", with: "")
            .replacingOccurrences(of: "git@", with: "")
            .replacingOccurrences(of: ".git", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func gitPush(tagName: String? = nil) async throws {
        let repoURL = try await CI.gitRepositoryURL()
        
        if let tagName {
            try await CI.run(.name("git"), ["tag", tagName])
            try await CI.run(.name("git"), ["push", "https://\(repoURL)", tagName])
        } else {
            try await CI.run(.name("git"), ["push", "https://\(repoURL)"])
        }
    }
}

import ArgumentParser
import Foundation
import Yams

enum Profile: String, ExpressibleByArgument {
    case debug = "dbg"
    case reldbg, release
}

enum Target: String, ExpressibleByArgument, CaseIterable {
    case iOS = "aarch64-apple-ios"
    case simulatorARM64 = "aarch64-apple-ios-sim"
    case simulatorIntel = "x86_64-apple-ios"
    case macARM64 = "aarch64-apple-darwin"
    case macIntel = "x86_64-apple-darwin"
}

struct BuildSDK: ParsableCommand {
    static var configuration = CommandConfiguration(abstract: "A tool to checkout and build MatrixRustSDK locally for development.")
    
    @Argument(help: "An optional argument to specify a branch of the SDK.")
    var branch: String?
    
    @Option(help: "The target to build for such as aarch64-apple-ios. Omit this option to build for all targets.")
    var target: Target?
    
    @Option(help: "The profile to use when building the SDK. Omit this option to build in debug mode.")
    var profile: Profile = .debug

    enum Error: LocalizedError {
        case rustupOutputFailure
        case missingRustTargets([String])
        case failureParsingProjectYAML
        
        var errorDescription: String? {
            switch self {
            case .missingRustTargets(let missingTargets):
                return """
                Rust is missing the necessary targets to build the SDK.
                Run the following command to install them:
                
                rustup target add \(missingTargets.joined(separator: " ")) --toolchain nightly
                
                """
            default:
                return nil
            }
        }
    }
    
    func run() throws {
        try checkRustupTargets()
        try cloneSDKIfNeeded()
        try checkoutBranchIfSupplied()
        try buildFramework()
        try updateXcodeProject()
        try generateSDKMocks()
    }
    
    /// Checks that all of the required targets have been added through rustup
    /// but only when the ``target`` option hasn't been supplied.
    func checkRustupTargets() throws {
        guard target == nil else { return }
        guard let output = try Utilities.zsh("rustup show") else { throw Error.rustupOutputFailure }
        
        var requiredTargets = Target.allCases.reduce(into: [String: Bool]()) { partialResult, target in
            partialResult[target.rawValue] = false
        }
        
        output.enumerateLines { line, _ in
            if requiredTargets.keys.contains(line) {
                requiredTargets[line] = true
            }
        }
        
        let missingTargets = requiredTargets.compactMap { !$0.value ? $0.key : nil }
        guard missingTargets.isEmpty else { throw Error.missingRustTargets(missingTargets) }
    }
    
    /// Clones the Rust SDK if a copy isn't found in the parent directory.
    func cloneSDKIfNeeded() throws {
        guard !FileManager.default.fileExists(atPath: Utilities.sdkDirectoryURL.path) else { return }
        try Utilities.zsh("git clone https://github.com/matrix-org/matrix-rust-sdk", workingDirectoryURL: Utilities.parentDirectoryURL)
    }
    
    /// Checkout the specified branch of the SDK if supplied.
    func checkoutBranchIfSupplied() throws {
        guard let branch else { return }
        try Utilities.zsh("git checkout \(branch)", workingDirectoryURL: Utilities.sdkDirectoryURL)
    }
    
    /// Build the Rust SDK as an XCFramework with the debug profile.
    func buildFramework() throws {
        // unset fixed an issue where swift compilation prevents building from other targets
        // other than macOS X
        var buildCommand = "unset SDKROOT && cargo xtask swift build-framework"
        buildCommand.append(" --profile \(profile.rawValue)")
        if let target {
            buildCommand.append(" --only-target \(target.rawValue)")
        }
        try Utilities.zsh(buildCommand, workingDirectoryURL: Utilities.sdkDirectoryURL)
    }
    
    /// Update the Xcode project to use the build of the SDK.
    func updateXcodeProject() throws {
        try updateProjectYAML()
        try Utilities.zsh("xcodegen")
    }
    
    /// Update project.yml with the local path of the SDK.
    func updateProjectYAML() throws {
        let yamlURL = Utilities.projectDirectoryURL.appendingPathComponent("project.yml")
        let yamlString = try String(contentsOf: yamlURL)
        guard var projectConfig = try Yams.compose(yaml: yamlString) else { throw Error.failureParsingProjectYAML }
        
        projectConfig["packages"]?.mapping?["MatrixRustSDK"]? = ["path": "../matrix-rust-sdk"]
        
        let updatedYAMLString = try Yams.serialize(node: projectConfig)
        try updatedYAMLString.write(to: yamlURL, atomically: true, encoding: .utf8)
    }

    func generateSDKMocks() throws {
        var command = GenerateSDKMocks()
        command.version = "local"
        try command.run()
    }
}

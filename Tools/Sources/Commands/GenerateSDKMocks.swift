import ArgumentParser
import CommandLineTools
import Foundation

struct GenerateSDKMocks: AsyncParsableCommand {
    static let configuration = CommandConfiguration(abstract: "A tool to setup the mocks for the Matrix Rust SDK")
    
    @Argument(help: "The argument to specify a branch of the SDK. Use `local` to use your local version")
    var version: String
    
    func run() async throws {
        if version == "local" {
            try generateSDKMocks(ffiPath: "\(URL.sdkDirectory.path)/bindings/apple/generated/swift")
        } else {
            let path = try downloadSDK(version: version)
            try generateSDKMocks(ffiPath: "\(path)/Sources/MatrixRustSDK")
            try FileManager.default.removeItem(atPath: path)
        }
    }
    
    /// Generates the SDK mocks using Sourcery.
    func generateSDKMocks(ffiPath: String) throws {
        try Zsh.run(command: "sourcery --sources \(ffiPath) --templates Tools/Sourcery/SDKAutoMockable.stencil --output Components/SDKMocks/Sources/Generated/SDKGeneratedMocks.swift")
    }
    
    /// Clones the specified version of the Swift package and returns the path to the clone.
    func downloadSDK(version: String) throws -> String {
        let path = NSTemporaryDirectory().appending("matrix-rust-components-swift")
        try? FileManager.default.removeItem(atPath: path)
        try Zsh.run(command: "git clone --quiet --depth 1 --branch \(version) https://github.com/element-hq/matrix-rust-components-swift \(path)")
        return path
    }
}

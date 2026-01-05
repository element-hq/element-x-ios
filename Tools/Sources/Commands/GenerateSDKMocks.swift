import ArgumentParser
import CommandLineTools
import Foundation

struct GenerateSDKMocks: AsyncParsableCommand {
    enum GenerateSDKMocksError: Error {
        case invalidFileUrl
    }

    static let configuration = CommandConfiguration(abstract: "A tool to setup the mocks for the Matrix Rust SDK")

    @Argument(help: "The argument to specify a branch of the SDK. Use `local` to use your local version")
    var version: String

    private var fileURLFormat = "https://raw.githubusercontent.com/element-hq/matrix-rust-components-swift/%@/Sources/MatrixRustSDK/matrix_sdk_ffi.swift"

    func run() async throws {
        if version == "local" {
            try generateSDKMocks(ffiPath: "\(URL.sdkDirectory.path)/bindings/apple/generated/swift")
        } else {
            let path = try await downloadSDK(version: version)
            try generateSDKMocks(ffiPath: path)
            try FileManager.default.removeItem(atPath: path)
        }
    }

    /// Generates the SDK mocks using Sourcery.
    func generateSDKMocks(ffiPath: String) throws {
        try Zsh.run(command: "sourcery --sources \(ffiPath) --templates Tools/Sourcery/SDKAutoMockable.stencil --output SDKMocks/Sources/Generated/SDKGeneratedMocks.swift")
    }

    /// Downloads the specified version of the `matrix_sdk_ffi.swift` file and returns the path to the downloaded file.
    func downloadSDK(version: String) async throws -> String {
        let fileURLString = String(format: fileURLFormat, version)
        guard let fileURL = URL(string: fileURLString) else {
            throw GenerateSDKMocksError.invalidFileUrl
        }
        
        let (tempURL, _) = try await URLSession.shared.download(from: fileURL)
        let sdkFilePath = NSTemporaryDirectory().appending("matrix_sdk_ffi.swift")
        try FileManager.default.moveItem(at: tempURL, to: URL(fileURLWithPath: sdkFilePath))
        return sdkFilePath
    }
}

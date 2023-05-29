import ArgumentParser
import Foundation

struct GenerateSDKMocks: ParsableCommand {
    enum GenerateSDKMocksError: Error {
        case invalidFileUrl
    }

    static var configuration = CommandConfiguration(abstract: "A tool to setup the mocks for the Matrix Rust SDK")

    @Argument(help: "The argument to specify a branch of the SDK. Use `local` to use your local version")
    var version: String

    private var fileURLFormat = "https://raw.githubusercontent.com/matrix-org/matrix-rust-components-swift/%@/Sources/MatrixRustSDK/matrix_sdk_ffi.swift"

    func run() throws {
        if version == "local" {
            try generateSDKMocks(ffiPath: "\(Utilities.sdkDirectoryURL.path)/bindings/apple/generated/swift")
        } else {
            try downloadSDK(version: version) { path in
                try generateSDKMocks(ffiPath: path)
                try FileManager.default.removeItem(atPath: path)
            }
        }
    }

    /// Generates the SDK mocks using Sourcery.
    func generateSDKMocks(ffiPath: String) throws {
        try Utilities.zsh("sourcery --sources \(ffiPath) --sources ElementX/Sources/Mocks/SDK --templates Tools/Sourcery --output ElementX/Sources/Mocks/Generated/SDKGeneratedMocks.swift --args autoMockableImports=\"Foundation\",autoMockableImports=\"MatrixRustSDK\"")
    }

    /// Downloads the specified version of the `matrix_sdk_ffi.swift` file and returns the path to the downloaded file.
    func downloadSDK(version: String, completionHandler: @escaping (String) throws -> Void) throws {
        var sdkFilePath = ""
        let fileURLString = String(format: fileURLFormat, version)
        guard let fileURL = URL(string: fileURLString) else {
            throw GenerateSDKMocksError.invalidFileUrl
        }

        let semaphore = DispatchSemaphore(value: 0)

        let task = URLSession.shared.downloadTask(with: fileURL) { tempURL, _, error in
            guard let tempURL = tempURL else {
                if let error = error {
                    print("Error downloading SDK file: \(error)")
                } else {
                    print("Unknown error occurred while downloading SDK file.")
                }
                return
            }

            do {
                sdkFilePath = NSTemporaryDirectory().appending("matrix_sdk_ffi.swift")
                try FileManager.default.moveItem(at: tempURL, to: URL(fileURLWithPath: sdkFilePath))
                try completionHandler(sdkFilePath)
                semaphore.signal()
            } catch {
                print("Error setting up SDK: \(error)")
                semaphore.signal()
            }
        }

        task.resume()

        _ = semaphore.wait(timeout: .distantFuture)
    }
}

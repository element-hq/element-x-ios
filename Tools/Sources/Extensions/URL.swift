import ArgumentParser
import Foundation

extension URL {
    static var projectDirectory: URL {
        URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    }

    static var parentDirectory: URL {
        .projectDirectory.deletingLastPathComponent()
    }

    static var sdkDirectory: URL {
        .parentDirectory.appendingPathComponent("matrix-rust-sdk")
    }
}

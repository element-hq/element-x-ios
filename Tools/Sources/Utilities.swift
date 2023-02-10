import ArgumentParser
import Foundation

enum Utilities {
    enum Error: LocalizedError {
        case scriptFailed(command: String, path: String)

        var errorDescription: String? {
            switch self {
            case let .scriptFailed(command, path):
                return "command \(command) failed in path: \(path)"
            }
        }
    }

    static var projectDirectoryURL: URL { URL(filePath: FileManager.default.currentDirectoryPath) }

    /// Runs a command in zsh.
    @discardableResult
    static func zsh(_ command: String, workingDirectoryURL: URL = projectDirectoryURL) throws -> String? {
        let process = Process()
        process.executableURL = URL(filePath: "/bin/zsh")
        process.arguments = ["-c", command]
        process.currentDirectoryURL = workingDirectoryURL

        let outputPipe = Pipe()
        process.standardOutput = outputPipe

        try process.run()
        process.waitUntilExit()

        guard process.terminationReason == .exit, process.terminationStatus == 0 else { throw Error.scriptFailed(command: command, path: workingDirectoryURL.absoluteString) }

        guard let outputData = try outputPipe.fileHandleForReading.readToEnd() else { return nil }
        return String(data: outputData, encoding: .utf8)
    }
}

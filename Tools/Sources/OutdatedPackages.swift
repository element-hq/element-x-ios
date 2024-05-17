import ArgumentParser
import CommandLineTools
import Foundation

struct OutdatedPackages: ParsableCommand {
    static var configuration = CommandConfiguration(abstract: "A tool to check outdated package dependencies. Please make sure you have already run setup-project before using this tool.")

    private var projectSwiftPMDirectoryURL: URL { .projectDirectory.appendingPathComponent("ElementX.xcodeproj/project.xcworkspace/xcshareddata/swiftpm") }

    func run() throws {
        try checkToolsDependencies()
        try checkProjectDependencies()
    }

    func checkToolsDependencies() throws {
        guard let output = try Zsh.run(command: "swift outdated"), !output.isEmpty else { return }
        print("outdated tools Swift packages:\n\(output)")
    }

    func checkProjectDependencies() throws {
        guard let output = try Zsh.run(command: "swift outdated", directory: projectSwiftPMDirectoryURL), !output.isEmpty else { return }
        print("outdated project Swift packages:\n\(output)")
    }
}

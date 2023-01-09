import Foundation
import PackagePlugin

@main
struct SwiftLint: CommandPlugin {
    func performCommand(context: PackagePlugin.PluginContext, arguments: [String]) async throws {
        let swiftlint = try context.tool(named: "swiftlint")
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: swiftlint.path.string)
        process.currentDirectoryURL = URL(fileURLWithPath: context.package.directory.string)
        try process.run()
    }
}

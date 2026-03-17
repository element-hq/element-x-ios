import ArgumentParser
import Foundation
import Yams

struct TagNightly: AsyncParsableCommand {
    static let configuration = CommandConfiguration(abstract: "Tags the current commit as a nightly build and pushes the tag.")

    @Option(help: "The build number to include in the tag.")
    var buildNumber: String

    func run() async throws {
        guard !buildNumber.isEmpty else {
            throw ValidationError("Invalid build number.")
        }
        
        try await CI.gitConfigureGlobals()

        let currentVersion = try CI.readMarketingVersion()
        let tagName = "nightly/\(currentVersion).\(buildNumber)"
        
        try await CI.gitPush(tagName: tagName)

        logger.info("\n🚀 Successfully tagged nightly: \(tagName)\n")
    }
}

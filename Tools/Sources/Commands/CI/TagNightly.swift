import ArgumentParser
import CommandLineTools
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
        
        guard let apiToken = ProcessInfo.processInfo.environment["GITHUB_TOKEN"],
              !apiToken.isEmpty else {
            throw ValidationError("Invalid GitHub API token. Please set the GITHUB_TOKEN environment variable.")
        }
        
        let repoURL = try getRepoURL()

        try await CI.run(.name("git"), ["config", "--global", "user.name", "Element CI"])
        try await CI.run(.name("git"), ["config", "--global", "user.email", "ci@element.io"])

        let currentVersion = try CI.readMarketingVersion()
        let tagName = "nightly/\(currentVersion).\(buildNumber)"
        try await CI.run(.name("git"), ["tag", tagName])
        
        try await CI.run(.name("git"), ["push", "https://\(apiToken)@\(repoURL)", tagName])

        logger.info("\n🚀 Successfully tagged nightly: \(tagName)\n")
    }

    // MARK: - Private

    private func getRepoURL() throws -> String {
        guard let rawURL = try Zsh.run(command: "git ls-remote --get-url origin") else {
            throw ValidationError("Could not determine the git remote URL.")
        }

        return
            rawURL
                .replacingOccurrences(of: "http://", with: "")
                .replacingOccurrences(of: "https://", with: "")
                .replacingOccurrences(of: "git@", with: "")
                .replacingOccurrences(of: ".git", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

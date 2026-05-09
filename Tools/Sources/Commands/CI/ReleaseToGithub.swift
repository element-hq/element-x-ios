import ArgumentParser
import Foundation
import Yams

struct ReleaseToGitHub: AsyncParsableCommand {
    static let configuration = CommandConfiguration(commandName: "release-to-github",
                                                    abstract: "Creates a GitHub release and updates CHANGES.md with generated release notes.")

    enum ReleaseError: LocalizedError {
        case missingGitHubToken
        case failedToCreateRelease(String)
        case failedToParseResponse
        case missingReleaseNotes
        case failedToReadVersion

        var errorDescription: String? {
            switch self {
            case .missingGitHubToken:
                return "The GITHUB_TOKEN environment variable is not set."
            case .failedToCreateRelease(let message):
                return "Failed to create GitHub release: \(message)"
            case .failedToParseResponse:
                return "Failed to parse the GitHub API response."
            case .missingReleaseNotes:
                return "The generated release notes are empty."
            case .failedToReadVersion:
                return "Failed to read the marketing version from project.yml."
            }
        }
    }

    func run() async throws {
        let currentVersion = try CI.readMarketingVersion()
        logger.info("Creating GitHub release for version \(currentVersion)…")

        let releaseBody = try await createGitHubRelease(version: currentVersion)

        try updateChangelog(version: currentVersion, generatedNotes: releaseBody)

        let changesFilePath = URL.projectDirectory.appendingPathComponent("CHANGES.md").path
        try await CI.run(.name("git"), ["add", changesFilePath])

        logger.info("Successfully created GitHub release \(currentVersion) and updated CHANGES.md.")
        
        let targetFilePath = "project.yml"
        let xcodeProjPath = "ElementX.xcodeproj"

        guard let newVersion = bumpPatchVersion(currentVersion) else {
            throw ValidationError("Invalid version format: \(currentVersion)")
        }

        // Bump the patch version using sed (preserves file formatting)
        try await CI.run(.name("sed"), ["-i", "", "s/MARKETING_VERSION: \(currentVersion)/MARKETING_VERSION: \(newVersion)/g", targetFilePath])
        logger.info("Version updated from \(currentVersion) to \(newVersion)")

        try await CI.run(.name("xcodegen"))

        try await CI.gitConfigureGlobals()

        try await CI.run(.name("git"), ["add", targetFilePath, xcodeProjPath])
        try await CI.run(.name("git"), ["commit", "-m", "Prepare next release"])
        
        try await CI.gitPush()

        try await rebaseMainOntoCurrentBranch()
    }

    // MARK: - Private

    private func createGitHubRelease(version: String) async throws -> String {
        guard let apiToken = ProcessInfo.processInfo.environment["GITHUB_TOKEN"], !apiToken.isEmpty
        else {
            throw ReleaseError.missingGitHubToken
        }
        
        let url = URL(string: "https://api.github.com/repos/element-hq/element-x-ios/releases")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = ["tag_name": "release/\(version)",
                                   "name": version,
                                   "generate_release_notes": true]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ReleaseError.failedToParseResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw ReleaseError.failedToCreateRelease("HTTP \(httpResponse.statusCode): \(errorBody)")
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let releaseBody = json["body"] as? String else {
            throw ReleaseError.failedToParseResponse
        }
        
        return releaseBody
    }

    private func updateChangelog(version: String, generatedNotes: String) throws {
        let changesURL = URL.projectDirectory.appending(component: "CHANGES.md")

        // Clean up the generated notes: remove HTML comments and adjust header levels
        let cleanedNotes = generatedNotes
            .replacingOccurrences(of: "<!-- .*? -->", with: "", options: .regularExpression)
            .replacingOccurrences(of: "### ", with: "\n")
            .replacingOccurrences(of: "## ", with: "### ")

        guard !cleanedNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ReleaseError.missingReleaseNotes
        }

        let releaseDate = Date().formatted(.iso8601.year().month().day())

        let existingContent = try String(contentsOf: changesURL)
        let newContent = "## Changes in \(version) (\(releaseDate))\(cleanedNotes)\n\n\(existingContent)"

        try newContent.write(to: changesURL, atomically: true, encoding: .utf8)
        logger.info("Updated CHANGES.md with release notes.")
    }
    
    private func bumpPatchVersion(_ version: String) -> String? {
        let regex = /^(\d{2})\.(\d{2})\.(\d+)$/
        guard let match = version.firstMatch(of: regex), var patch = Int(match.3) else {
            return nil
        }

        let year = String(match.1)
        let month = String(match.2)
        patch = patch + 1
        
        return "\(year).\(month).\(patch)"
    }
    
    private func rebaseMainOntoCurrentBranch() async throws {
        guard let currentBranch = try await CI.run(.name("git"), ["rev-parse", "--abbrev-ref", "HEAD"], output: .string(limit: 4096))
            .standardOutput.map({ $0.trimmingCharacters(in: .whitespacesAndNewlines) }) else {
            throw ValidationError("Could not determine the current branch.")
        }
        
        logger.info("Current branch: \(currentBranch)")

        try await CI.run(.name("git"), ["reset", "--hard"])
        try await CI.run(.name("git"), ["checkout", "main"])
        try await CI.run(.name("git"), ["pull", "origin", "main"])
        try await CI.run(.name("git"), ["rebase", currentBranch])

        try await CI.gitPush()

        logger.info("Successfully rebased main onto \(currentBranch)")
    }
}

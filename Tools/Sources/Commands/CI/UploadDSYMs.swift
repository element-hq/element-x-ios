import ArgumentParser
import CommandLineTools
import Foundation

struct UploadDSYMs: AsyncParsableCommand {
    static let configuration = CommandConfiguration(commandName: "upload-dsyms",
                                                    abstract: "Uploads dSYMs to Sentry using sentry-cli.",
                                                    discussion: "Requires the SENTRY_AUTH_TOKEN environment variable to be set.")

    @Option(help: "The path to the dSYMs directory or file to upload.")
    var dsymPath: String

    @Option(help: "The Sentry organization slug.")
    var orgSlug = "element"

    @Option(help: "The Sentry project slug.")
    var projectSlug = "element-x-ios"

    @Option(help: "The Sentry server URL.")
    var url = "https://sentry.tools.element.io/"

    @Option(help: "The maximum number of upload attempts.")
    var maxRetries = 5

    func run() async throws {
        guard let authToken = ProcessInfo.processInfo.environment["SENTRY_AUTH_TOKEN"],
              !authToken.isEmpty else {
            throw ValidationError("SENTRY_AUTH_TOKEN environment variable is not set.")
        }

        let command = """
        sentry-cli --url "\(url)" dif upload \
            --auth-token "\(authToken)" \
            --org "\(orgSlug)" \
            --project "\(projectSlug)" \
            --log-level debug \
            "\(dsymPath)"
        """

        var lastError: Swift.Error?

        for attempt in 1...maxRetries {
            do {
                logger.info("\n📡 Uploading dSYMs to Sentry (attempt \(attempt)/\(maxRetries))…\n")
                try await CI.run(.path("/bin/zsh"), ["-cu", command])
                logger.info("\n✅ Successfully uploaded dSYMs to Sentry.\n")
                return
            } catch {
                lastError = error
                logger.error("\n❌ Sentry upload attempt \(attempt) failed: \(error.localizedDescription)\n")
            }
        }

        if let lastError {
            throw lastError
        }
    }
}

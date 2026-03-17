import ArgumentParser
import Foundation

struct ConfigureProduction: AsyncParsableCommand {
    static let configuration = CommandConfiguration(abstract: "Configures the project for a production build.")
    
    func run() async throws {
        try await CI.run(.name("swift"), ["run", "pipeline", "update-foss-secrets"])
        try await CI.run(.name("xcodegen"))
    }
}

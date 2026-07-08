import ArgumentParser
import Foundation
import Yams

struct ConfigureNightly: AsyncParsableCommand {
    static let configuration = CommandConfiguration(abstract: "Configures the project for a Nightly build.",
                                                    discussion: "Adds the Nightly variant to project.yml, updates secrets, runs xcodegen, and generates the app icon banner.")
    
    @Option(help: "The build number to display on the app icon banner.")
    var buildNumber: String
    
    func run() async throws {
        guard !buildNumber.isEmpty else {
            throw ValidationError("Invalid build number.")
        }
        
        try addNightlyVariant()
        
        try await CI.run(.name("swift"), ["run", "pipeline", "update-foss-secrets"])
        try await CI.run(.name("xcodegen"))
        
        try await generateAppIconBanner(buildNumber: buildNumber)
    }
    
    /// Adds the Nightly variant include path to `project.yml` if it isn't already present.
    private func addNightlyVariant() throws {
        let projectURL = URL.projectDirectory.appending(component: "project.yml")
        let projectString = try String(contentsOf: projectURL, encoding: .utf8)
        guard var projectConfig = try Yams.compose(yaml: projectString) else {
            throw ValidationError("Failed to parse project.yml.")
        }
        
        // Check if the nightly variant is already included
        if projectConfig["include"]?.sequence?.contains(where: { $0.mapping?["path"] == "Variants/Nightly/nightly.yml" }) == false {
            projectConfig["include"]?.sequence?.append(["path": "Variants/Nightly/nightly.yml"])
        }
        
        let updatedYAMLString = try Yams.serialize(node: projectConfig)
        try updatedYAMLString.write(to: projectURL, atomically: true, encoding: .utf8)
    }
    
    /// Generates the app icon banner with version and build number.
    private func generateAppIconBanner(buildNumber: String) async throws {
        let iconPath = "Variants/Nightly/Resources/NightlyAppIcon.icon/Assets/Version.png"
        try await AppIconBanner.parse([iconPath, "--build-number", buildNumber]).run()
    }
}

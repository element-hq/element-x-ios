import ArgumentParser
import CommandLineTools
import Foundation

struct BumpCalendarVersion: ParsableCommand {
    static let configuration = CommandConfiguration(abstract: "A tool that bumps the CalVer every month (if needed), setting the patch back to 0.",
                                                    discussion: "The tool assumes the release will be published in 6-days so bumps early.")

    func run() throws {
        try updateProjectYAML()
        try Zsh.run(command: "xcodegen")
    }
    
    /// Updates the project YAML with the new version.
    private func updateProjectYAML() throws {
        let yamlURL = URL.projectDirectory.appendingPathComponent("project.yml")
        let yamlString = try String(contentsOf: yamlURL)
        
        // Use regex instead of Yams to preserve any whitespace, comments etc in the file.
        let marketingVersionRegex = /MARKETING_VERSION:\s*([^\s]+)/
        var updatedYAMLString = ""
        
        yamlString.enumerateLines { line, _ in
            let processedLine = if let match = line.firstMatch(of: marketingVersionRegex),
                                   let newVersion = try? generateNewVersion(from: String(match.1)) {
                line.replacingOccurrences(of: match.1, with: newVersion)
            } else {
                line
            }
            
            updatedYAMLString.append(processedLine + "\n")
        }
        
        try updatedYAMLString.write(to: yamlURL, atomically: true, encoding: .utf8)
    }
    
    /// Returns the new version string if a change is necessary.
    ///
    /// **Note:** This tool does *not* handle patch bumps, those are done automatically in the release script.
    private func generateNewVersion(from currentVersion: String) throws -> String? {
        let releaseDate = Date.now.addingTimeInterval(6 * 24 * 60 * 60) // Always assume we're building the RC.
        let releaseYear = Calendar.current.component(.year, from: releaseDate) % 1000 // We use the short year.
        let releaseMonth = Calendar.current.component(.month, from: releaseDate)
        let versionComponents = currentVersion.split(separator: ".").compactMap { Int($0) }
        
        guard versionComponents.count == 3 else { fatalError("Unexpected version format: \(currentVersion)") }
        
        if versionComponents[0] != releaseYear || versionComponents[1] != releaseMonth {
            return "\(releaseYear).\(String(format: "%02d", releaseMonth)).0"
        } else {
            return nil
        }
    }
}

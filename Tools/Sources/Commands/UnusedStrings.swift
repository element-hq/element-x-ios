import ArgumentParser
import CommandLineTools
import Foundation

struct UnusedStrings: ParsableCommand {
    static let configuration = CommandConfiguration(abstract: "Generates a report showing which strings aren't used in the project.")
    
    @Flag(help: "Save the results to disk instead of printing them.")
    var saveToFile = false

    func run() throws {
        try peripheryScan()
    }

    func peripheryScan() throws {
        print("Analysing project, this may take a while…")
        
        // Uses the existing .periphery.yml with small tweaks to the output.
        let command = "periphery scan --quiet --relative-results --report-include ElementX/Sources/Generated/Strings.swift"
        let output = try Zsh.run(command: command)
        
        guard let output else {
            print("Nothing reported.")
            return
        }
        
        if saveToFile {
            try output.write(to: .projectDirectory.appending(component: "Unused Strings.txt"), atomically: true, encoding: .utf8)
            print("Report saved: Unused Strings.txt")
        } else {
            print(output)
        }
    }
}

import Foundation

// XcodeGen (via XcodeProj) serializes schemes slightly differently to Xcode, so Xcode
// rewrites them as soon as it touches them. Match Xcode's output to avoid the churn.
// Remove once https://github.com/tuist/XcodeProj/pull/1189 ships in XcodeGen.

let schemesDirectory = URL(filePath: CommandLine.arguments[1])

for url in try FileManager.default.contentsOfDirectory(at: schemesDirectory, includingPropertiesForKeys: nil)
    where url.pathExtension == "xcscheme" {
    var scheme = try String(contentsOf: url, encoding: .utf8)
    
    scheme.replace(#/"\s*(runPostActionsOnFailure|onlyGenerateCoverageForSpecifiedTargets) = "NO">/#, with: "\">")
    scheme.replace(#/\s*<CommandLineArguments>\s*<\/CommandLineArguments>/#, with: "")
    scheme.replace(#/default = (?<value>"[^"]*")(?<indent>\s*)reference = (?<reference>"[^"]*")/#) { match in
        "reference = \(match.reference)\(match.indent)default = \(match.value)"
    }
    
    // Xcode writes test plans last and omits the then redundant empty testables.
    if let testPlans = scheme.firstMatch(of: #/\s*<TestPlans>.*?<\/TestPlans>/#.dotMatchesNewlines()) {
        scheme.removeSubrange(testPlans.range)
        scheme.replace(#/\s*<Testables>\s*<\/Testables>/#, with: "")
        scheme.replace(#/\s*<\/TestAction>/#) { testPlans.output + $0.output }
    }
    
    try scheme.write(to: url, atomically: true, encoding: .utf8)
}

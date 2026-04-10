import ArgumentParser
import CommandLineTools
import Foundation

struct DownloadStrings: ParsableCommand {
    static let configuration = CommandConfiguration(abstract: "A tool to download localizable strings from localazy")

    @Flag(help: "Use to download translation keys for all languages")
    var allLanguages = false

    func run() throws {
        try localazyDownload()
        try sortStringsFiles()
        try swiftgen()
    }

    private func localazyDownload() throws {
        let arguments = allLanguages ? " all" : ""
        try Zsh.run(command: "localazy download\(arguments)")
    }
    
    private func sortStringsFiles() throws {
        let localizationsURL = URL(fileURLWithPath: "ElementX/Resources/Localizations")
        let fileManager = FileManager.default
        
        guard let enumerator = fileManager.enumerator(at: localizationsURL,
                                                      includingPropertiesForKeys: nil) else {
            return
        }
        
        for case let fileURL as URL in enumerator {
            switch fileURL.pathExtension {
            case "strings":
                try sortStringsFile(at: fileURL)
            case "stringsdict":
                try sortStringsdictFile(at: fileURL)
            default:
                break
            }
        }
    }
    
    private func sortStringsFile(at url: URL) throws {
        let content = try String(contentsOf: url, encoding: .utf8)
        let lines = content.components(separatedBy: .newlines)
        
        let keyValueRegex = /^\s*".+"\s*=\s*".*";\s*$/
        
        let keyValueLines = lines.filter { $0.wholeMatch(of: keyValueRegex) != nil }
        
        guard !keyValueLines.isEmpty else { return }
        
        let sortedLines = keyValueLines.sorted { lhs, rhs in
            guard let lhsKey = extractKey(from: lhs),
                  let rhsKey = extractKey(from: rhs) else {
                return lhs < rhs
            }
            return lhsKey.localizedStandardCompare(rhsKey) == .orderedAscending
        }
        
        let sortedContent = sortedLines.joined(separator: "\n") + "\n"
        try sortedContent.write(to: url, atomically: true, encoding: .utf8)
    }
    
    private func sortStringsdictFile(at url: URL) throws {
        let data = try Data(contentsOf: url)
        let plist = try PropertyListSerialization.propertyList(from: data, format: nil)
        let xmlData = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
        try xmlData.write(to: url)
    }
    
    private func extractKey(from line: String) -> String? {
        guard let openQuote = line.firstIndex(of: "\"") else { return nil }
        let afterOpen = line.index(after: openQuote)
        guard let closeQuote = line[afterOpen...].firstIndex(of: "\"") else { return nil }
        return String(line[afterOpen..<closeQuote])
    }

    private func swiftgen() throws {
        try Zsh.run(command: "swiftgen config run --config Tools/SwiftGen/swiftgen-config.yml")
    }
}

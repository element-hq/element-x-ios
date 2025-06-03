import ArgumentParser
import Foundation

struct GenerateSAS: ParsableCommand {
    static let configuration = CommandConfiguration(abstract: "A tool to download and generate SAS localization strings")
    private static let defaultLanguage = "en"
    
    @Flag(name: .shortAndLong, help: "Increase output verbosity.")
    var verbose = false
    
    func run() throws {
        let baseURL = URL(string: "https://raw.githubusercontent.com/matrix-org/matrix-spec/main/data-definitions/sas-emoji.json")!
        
        printIfVerbose("Argument:")
        printIfVerbose(self)
        
        print("Downloading \(baseURL.absoluteString)…")
        
        guard let data = try? Data(contentsOf: baseURL),
              let json = try? JSONDecoder().decode([SASEmoji].self, from: data) else {
            print("Failed to download or parse JSON.")
            return
        }
        
        printIfVerbose("Json data:")
        printIfVerbose(json)
        
        var defaultTranslations = [String: String]()
        var cumulativeTranslations = [String: [String: String]]()
        
        cumulativeTranslations[Self.defaultLanguage] = [String: String]()
        for emoji in json {
            let description = emoji.description
            
            printIfVerbose("Description: \(description)")
            
            defaultTranslations[description] = description
            
            let translations = emoji.translatedDescriptions
            // en is not included since is the default language so we need to add it ourselves
            cumulativeTranslations[Self.defaultLanguage]![description] = description
            for (lang, translation) in translations {
                printIfVerbose("Lang: \(lang)")
                
                if cumulativeTranslations[lang] == nil {
                    cumulativeTranslations[lang] = [String: String]()
                }
                
                cumulativeTranslations[lang]![description] = translation
            }
        }
        
        printIfVerbose(defaultTranslations)
        printIfVerbose(cumulativeTranslations)
        
        for (lang, translations) in cumulativeTranslations {
            let iosLang = lang
                .replacingOccurrences(of: "_", with: "-")
                .appending(".lproj")
            
            writeToFile(file: "SAS.strings", dict: translations, subdirectory: iosLang)
        }
        
        print("Write completed")
    }
    
    private func writeToFile(file: String, dict: [String: String], subdirectory: String) {
        let fileDirectory = URL.projectDirectory.appendingPathComponent("ElementX/Resources/Localizations").appendingPathComponent(subdirectory)
        
        let filePath = fileDirectory.appendingPathComponent(file)
        
        print("Writing file \(filePath.path)")
        
        printIfVerbose("With")
        printIfVerbose(dict)
        
        do {
            // This will fail if the .lproj dir does not exist already, which is fine since we don't want to add translations for unsupported languages.
            try dict
                .sorted(by: { $0.key < $1.key })
                .map { "\"\($0.key.lowercased().replacingOccurrences(of: " ", with: "_"))\" = \"\($0.value)\";" }
                .joined(separator: "\n")
                .write(to: filePath, atomically: true, encoding: .utf8)
        } catch {
            print("Failed to write file \(filePath.path): \(error)")
        }
    }
    
    private struct SASEmoji: Codable {
        let number: Int
        let emoji, description, unicode: String
        let translatedDescriptions: [String: String?]
        
        enum CodingKeys: String, CodingKey {
            case number, emoji, description, unicode
            case translatedDescriptions = "translated_descriptions"
        }
    }
    
    private func printIfVerbose(_ items: Any...) {
        if verbose {
            print(items)
        }
    }
}

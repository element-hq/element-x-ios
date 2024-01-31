import ArgumentParser
import Foundation

struct GenerateSAS: ParsableCommand {
    static var configuration = CommandConfiguration(abstract: "A tool to download and generate SAS localization strings")
    private static let defaultLanguage = "en"
    
    @Flag(name: .shortAndLong, help: "Increase output verbosity.")
    var verbose = false

    func run() throws {
        let baseURL = URL(string: "https://raw.githubusercontent.com/matrix-org/matrix-spec/main/data-definitions/sas-emoji.json")!
        
        if verbose {
            print("Argument:")
            print(self)
        }
        
        print("Downloading \(baseURL.absoluteString)…")
        
        guard let data = try? Data(contentsOf: baseURL),
              let json = try? JSONDecoder().decode([SASEmoji].self, from: data) else {
            print("Failed to download or parse JSON.")
            return
        }
        
        if verbose {
            print("Json data:")
            print(json)
        }
        
        print()
        
        var defaultTranslations = [String: String]()
        var cumulativeTranslations = [String: [String: String]]()
        
        cumulativeTranslations[Self.defaultLanguage] = [String: String]()
        for emoji in json {
            let description = emoji.description
            
            if verbose {
                print("Description: \(description)")
            }
            
            defaultTranslations[description] = description
            
            let translations = emoji.translatedDescriptions
            // en is not included since is the default language so we need to add it ourselves
            cumulativeTranslations[Self.defaultLanguage]![description] = description
            for (lang, translation) in translations {
                if verbose {
                    print("Lang: \(lang)")
                }
                
                if cumulativeTranslations[lang] == nil {
                    cumulativeTranslations[lang] = [String: String]()
                }
                
                cumulativeTranslations[lang]![description] = translation
            }
        }
        
        if verbose {
            print(defaultTranslations)
            print(cumulativeTranslations)
        }
                        
        for (lang, translations) in cumulativeTranslations {
            let iosLang = lang
                .replacingOccurrences(of: "_", with: "-")
                .replacingOccurrences(of: "zh-rHant", with: "zh-Hant-TW")
                .appending(".lproj")
            
            writeToFile(file: "SAS.strings", dict: translations, subdirectory: iosLang)
        }
        
        if verbose {
            print("Write completed")
        }
    }
    
    private func writeToFile(file: String, dict: [String: String], subdirectory: String) {
        let projectDirectory = Utilities.projectDirectoryURL
        let fileDirectory = projectDirectory.appendingPathComponent("ElementX/Resources/Localizations").appendingPathComponent(subdirectory)
        
        let filePath = fileDirectory.appendingPathComponent(file)
        
        print("Writing file \(filePath.path)")
        
        if verbose {
            print("With")
            print(dict)
        }
        
        do {
            // This will fail is the .lproj dir does not exist already, which is fine since we don't want to add translations for unsupported languages.
            try dict.map { "\"\($0.key.lowercased().replacingOccurrences(of: " ", with: "_"))\" = \"\($0.value)\";" }
                .joined(separator: "\n")
                .write(to: filePath, atomically: true, encoding: .utf8)
        } catch {
            print("Failed to write file \(filePath.path): \(error)")
        }
    }
    
    struct SASEmoji: Codable {
        let number: Int
        let emoji, description, unicode: String
        let translatedDescriptions: [String: String?]

        enum CodingKeys: String, CodingKey {
            case number, emoji, description, unicode
            case translatedDescriptions = "translated_descriptions"
        }
    }
}

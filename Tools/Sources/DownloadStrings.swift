import ArgumentParser
import Foundation

struct DownloadStrings: ParsableCommand {
    static var configuration = CommandConfiguration(abstract: "A tool to download localizable strings from localazy")

    @Flag(help: "Use to download translation keys for all languages")
    var allLanguages = false

    func run() throws {
        try localazyDownload()
        try swiftgen()
    }

    private func localazyDownload() throws {
        let arguments = allLanguages ? " all" : ""
        try Utilities.zsh("localazy download\(arguments)")
    }

    private func swiftgen() throws {
        try Utilities.zsh("swiftgen config run --config Tools/SwiftGen/swiftgen-config.yml")
    }
}

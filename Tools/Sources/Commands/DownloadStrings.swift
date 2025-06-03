import ArgumentParser
import CommandLineTools
import Foundation

struct DownloadStrings: ParsableCommand {
    static let configuration = CommandConfiguration(abstract: "A tool to download localizable strings from localazy")

    @Flag(help: "Use to download translation keys for all languages")
    var allLanguages = false

    func run() throws {
        try localazyDownload()
        try swiftgen()
    }

    private func localazyDownload() throws {
        let arguments = allLanguages ? " all" : ""
        try Zsh.run(command: "localazy download\(arguments)")
    }

    private func swiftgen() throws {
        try Zsh.run(command: "swiftgen config run --config Tools/SwiftGen/swiftgen-config.yml")
    }
}

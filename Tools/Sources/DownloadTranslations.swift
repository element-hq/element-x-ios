import ArgumentParser
import Foundation

struct DownloadTranslations: ParsableCommand {
    static var configuration = CommandConfiguration(abstract: "A tool to download translations from localazy")

    @Flag(help: "Use to download translation keys for all languages")
    var all = false

    func run() throws {
        try localazyDownload()
    }

    private func localazyDownload() throws {
        let json = all ? "localazy-all.json" : "localazy-en.json"
        try Utilities.zsh("localazy download --config \(json)")
    }
}

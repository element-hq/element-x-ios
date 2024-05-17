import ArgumentParser
import CommandLineTools
import Foundation

struct Locheck: ParsableCommand {
    enum LocheckError: LocalizedError {
        case missingMint
        case outputError

        var errorDescription: String? {
            switch self {
            case .missingMint:
                return "💥 Unable to find mint. Fix by running:\nbrew install mint\n"
            case .outputError:
                return "💥 Failed to read the output from locheck."
            }
        }
    }

    static var configuration = CommandConfiguration(abstract: "A tool that verifies bad strings contained in localization files")

    private var stringsDirectoryURL: URL {
        .projectDirectory.appendingPathComponent("ElementX/Resources/Localizations")
    }

    func run() throws {
        try checkMint()
        try checkStrings()
    }

    func checkStrings() throws {
        guard let output = try Zsh.run(command: "mint run locheck discoverlproj --ignore-missing --ignore lproj_file_missing_from_translation --treat-warnings-as-errors \(stringsDirectoryURL.path)") else {
            throw LocheckError.missingMint
        }
        print(output)
    }

    private func checkMint() throws {
        let result = try Zsh.run(command: "which mint")

        if result?.contains("not found") == true {
            throw LocheckError.missingMint
        }
    }
}

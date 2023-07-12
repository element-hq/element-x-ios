import ArgumentParser
import Foundation
import Yams

struct SetupProject: ParsableCommand {
    static var configuration = CommandConfiguration(abstract: "A tool to setup the required components to efficiently run and contribute to Element X iOS")

    @Flag(help: "Use this only on ci to avoid installing failing packages")
    var ci = false

    enum Error: LocalizedError {
        case errorReadingProjectYAML

        var errorDescription: String? {
            switch self {
            case .errorReadingProjectYAML:
                return "Error reading/parsing the file 'project.yml'"
            }
        }
    }

    func run() throws {
        try setupGitHooks()
        try brewBundleInstall()
        try mintPackagesInstall()
        try setupMapLibreKey()
        try xcodegen()
    }

    func setupGitHooks() throws {
        try Utilities.zsh("git config core.hooksPath .githooks")
    }

    func brewBundleInstall() throws {
        try Utilities.zsh("brew install xcodegen swiftgen swiftformat git-lfs sourcery mint kiliankoe/formulae/swift-outdated localazy/tools/localazy")
        if !ci {
            try Utilities.zsh("brew install swiftlint")
        }
    }

    func mintPackagesInstall() throws {
        try Utilities.zsh("mint install Asana/locheck")
    }

    func setupMapLibreKey() throws {
        guard !ci else {
            return
        }

        guard let maplibreAPIKey = try Utilities.zsh("cat ./.maplibre_key") else {
            print("Error loading the file '.maplibre_key' ensure to have one in the project root directory")
            return
        }

        guard
            let yamlFile = try Utilities.zsh("cat ./project.yml"),
            var loadedYAML = try Yams.load(yaml: yamlFile) as? [String: Any],
            var settings = loadedYAML["settings"] as? [String: Any]
        else {
            throw Error.errorReadingProjectYAML
        }

        settings["MAPLIBRE_API_KEY"] = maplibreAPIKey
        loadedYAML["settings"] = settings

        let updatedYAML = try Yams.dump(object: loadedYAML)

        try Utilities.zsh(
            """
            cat << "EOF" > ./project.yml
            \(updatedYAML)
            EOF
            """
        )
    }

    func xcodegen() throws {
        try Utilities.zsh("xcodegen")
    }
}

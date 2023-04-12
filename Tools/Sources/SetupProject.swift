import ArgumentParser
import Foundation

struct SetupProject: ParsableCommand {
    static var configuration = CommandConfiguration(abstract: "A tool to setup the required components to efficiently run and contribute to Element X iOS")

    @Flag(help: "Use this only on ci to avoid installing failing packages")
    var ci = false

    func run() throws {
        try setupGitHooks()
        try brewBundleInstall()
        try mintPackagesInstall()
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

    func mintPackagesInstall() throws {
        try Utilities.zsh("mint install Asana/locheck")
    }

    func xcodegen() throws {
        try Utilities.zsh("xcodegen")
    }
}

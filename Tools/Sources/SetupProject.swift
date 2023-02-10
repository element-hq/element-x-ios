import ArgumentParser
import Foundation

struct SetupProject: ParsableCommand {
    static var configuration = CommandConfiguration(abstract: "A tool to setup the required components to efficiently run and contribute to Element X iOS")

    func run() throws {
        try setupGitHooks()
        try brewBundleInstall()
        try xcodegen()
    }

    func setupGitHooks() throws {
        try Utils.zsh("git config core.hooksPath .githooks")
    }

    func brewBundleInstall() throws {
        try Utils.zsh("brew bundle install")
    }

    func xcodegen() throws {
        try Utils.zsh("xcodegen")
    }
}

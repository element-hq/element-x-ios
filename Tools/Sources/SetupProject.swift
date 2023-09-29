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
        try linkGitLFS()
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
    
    func linkGitLFS() throws {
        guard let gitPath = try Utilities.zsh("git --exec-path")?.replacingOccurrences(of: "\n", with: "") else { return }
        
        let lfsPath = URL(fileURLWithPath: gitPath).appendingPathComponent("git-lfs").path
        
        guard !FileManager.default.fileExists(atPath: lfsPath) else {
            print("Git LFS already linked.")
            return
        }
        
        try Utilities.zsh("ln -s \"$(which git-lfs)\" \"\(lfsPath)\"")
    }

    func xcodegen() throws {
        try Utilities.zsh("xcodegen")
    }
}

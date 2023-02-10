import ArgumentParser
import Foundation

@main
struct Tools: ParsableCommand {
    static var configuration = CommandConfiguration(abstract: "A collection of command line tools for ElementX",
                                                    subcommands: [BuildSDK.self,
                                                                  SetupProject.self])
}

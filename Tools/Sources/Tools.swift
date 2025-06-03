import ArgumentParser
import Foundation

@main
struct Tools: AsyncParsableCommand {
    static let configuration = CommandConfiguration(abstract: "A collection of command line tools for ElementX",
                                                    subcommands: [BuildSDK.self,
                                                                  SetupProject.self,
                                                                  OutdatedPackages.self,
                                                                  DownloadStrings.self,
                                                                  Locheck.self,
                                                                  GenerateSDKMocks.self,
                                                                  GenerateSAS.self,
                                                                  AppIconBanner.self,
                                                                  UnusedStrings.self,
                                                                  BumpCalendarVersion.self])
}

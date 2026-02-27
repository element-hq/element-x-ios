import ArgumentParser
import CommandLineTools
import Foundation

struct UITests: AsyncParsableCommand {
    static let configuration = CommandConfiguration(commandName: "ui-tests",
                                                    abstract: "Runs the UI test CI workflow for a specific device type.",
                                                    discussion: """
                                                    Examples:
                                                      swift run tools ci ui-tests --device-type iPhone
                                                      swift run tools ci ui-tests --device-type iPad
                                                      swift run tools ci ui-tests --device-type iPhone --test-name "ClassName/testName"
                                                    """)

    enum DeviceType: String, CaseIterable, ExpressibleByArgument {
        case iPhone
        case iPad
    }

    @Option(help: "The device type to test (iPhone or iPad).")
    var deviceType: DeviceType

    @Option(help: "iOS version for the simulator.")
    var osVersion = "26.1"

    @Option(help: "Run only a specific test (format: 'ClassName/testName').")
    var testName: String?

    private var simulatorName: String {
        switch deviceType {
        case .iPhone: "iPhone-\(osVersion)"
        case .iPad: "iPad-\(osVersion)"
        }
    }

    private var simulatorType: String {
        switch deviceType {
        case .iPhone: "com.apple.CoreSimulator.SimDeviceType.iPhone-17"
        case .iPad: "com.apple.CoreSimulator.SimDeviceType.iPad-A16"
        }
    }

    /// We used to run these simultaneously on iPhone and iPad but it is *really* slow on GitHub runners.
    /// Presumably because launching 2 simulators uses more memory than the runner has available.
    func run() async throws {
        var args = [
            "--scheme", "UITests",
            "--device", simulatorName,
            "--os-version", osVersion,
            "--create-simulator-name", simulatorName,
            "--create-simulator-type", simulatorType
        ]

        if let testName {
            args += ["--test-name", testName]
        }

        var testsFailed = false
        do {
            print("\n🧪 Running UI tests (\(deviceType.rawValue))…\n")
            try await RunTests.parse(args).run()
        } catch {
            testsFailed = true
            print("\n❌ UI tests (\(deviceType.rawValue)) failed.\n")
        }
        
        await CI.zipResults(bundles: ["UITests.xcresult"],
                            outputName: "UITests.xcresult.zip")
        
        await CI.collectCoverage(resultBundle: "UITests.xcresult", outputName: "ui-cobertura.xml")
        await CI.collectTestResults(resultBundle: "UITests.xcresult", outputName: "ui-junit.xml")

        if testsFailed {
            throw ExitCode.failure
        }

        print("\n✅ UI tests (\(deviceType.rawValue)) passed.\n")
    }
}

//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import SwiftUI
import XCTest

@testable import ElementX
@testable import SnapshotTesting

#if canImport(AccessibilitySnapshot)
import AccessibilitySnapshot
#endif

class PreviewTests: XCTestCase {
    private let deviceConfig: ViewImageConfig = .iPhoneX
    private var simulatorDevice: String? = "iPhone14,6" // iPhone SE 3rd Generation
    private var requiredOSVersion = (major: 18, minor: 0)
    private let snapshotDevices = ["iPhone 16", "iPad"]

    override func setUp() {
        super.setUp()

        checkEnvironments()
        UIView.setAnimationsEnabled(false)
    }
    
    /// Check environments to avoid problems with snapshots on different devices or OS.
    private func checkEnvironments() {
        if let simulatorDevice {
            let deviceModel = ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"]
            guard deviceModel?.contains(simulatorDevice) ?? false else {
                fatalError("\(deviceModel ?? "Unknown") is the wrong one. Switch to using \(simulatorDevice) for these tests.")
            }
        }

        let osVersion = ProcessInfo().operatingSystemVersion
        guard osVersion.majorVersion == requiredOSVersion.major, osVersion.minorVersion == requiredOSVersion.minor else {
            fatalError("Switch to iOS \(requiredOSVersion) for these tests.")
        }
        guard !snapshotDevices.isEmpty else {
            fatalError("Specify at least one snapshot device to test on.")
        }
    }
    
    // MARK: - Snapshots

    func assertSnapshots(matching preview: _Preview, testName: String = #function) {
        for deviceName in snapshotDevices {
            guard var device = PreviewDevice(rawValue: deviceName).snapshotDevice() else {
                fatalError("Unknown device name: \(deviceName)")
            }
            // Ignore specific device safe area (using the workaround value to fix rendering issues).
            device.safeArea = .one
            // Ignore specific device display scale
            let traits = UITraitCollection(displayScale: 2.0)
            if let failure = assertSnapshots(matching: AnyView(preview.content),
                                             name: preview.displayName,
                                             isScreen: preview.layout == .device,
                                             device: device,
                                             testName: testName + deviceName + "-" + localeCode,
                                             traits: traits) {
                XCTFail(failure)
            }
        }
    }
    
    private var localeCode: String {
        if UserDefaults.standard.bool(forKey: "NSDoubleLocalizedStrings") {
            return "pseudo"
        }
        return languageCode + "-" + regionCode
    }

    private var languageCode: String {
        Locale.current.language.languageCode?.identifier ?? ""
    }

    private var regionCode: String {
        Locale.current.language.region?.identifier ?? ""
    }

    private func assertSnapshots(matching view: AnyView,
                                 name: String?, isScreen: Bool,
                                 device: ViewImageConfig,
                                 testName: String = #function,
                                 traits: UITraitCollection = .init()) -> String? {
        var delay: TimeInterval = 0
        var precision: Float = 1
        var perceptualPrecision: Float = 1

        let view = view
            .onPreferenceChange(SnapshotDelayPreferenceKey.self) { delay = $0 }
            .onPreferenceChange(SnapshotPrecisionPreferenceKey.self) { precision = $0 }
            .onPreferenceChange(SnapshotPerceptualPrecisionPreferenceKey.self) { perceptualPrecision = $0 }

        let matchingView = isScreen ? AnyView(view) : AnyView(view
            .frame(width: device.size?.width)
            .fixedSize(horizontal: false, vertical: true)
        )
        
        let failure = withSnapshotTesting(record: .missing) {
            verifySnapshot(of: matchingView,
                           as: .prefireImage(precision: { precision },
                                             perceptualPrecision: { perceptualPrecision },
                                             duration: { delay },
                                             layout: isScreen ? .device(config: device) : .sizeThatFits,
                                             traits: traits),
                           named: name,
                           testName: testName)
        }

        #if canImport(AccessibilitySnapshot)
        let vc = UIHostingController(rootView: matchingView)
        vc.view.frame = UIScreen.main.bounds
        assertSnapshot(matching: vc,
                       as: .wait(for: delay, on: .accessibilityImage(showActivationPoints: .always)),
                       named: name.flatMap { $0 + ".accessibility" },
                       testName: testName)
        #endif
        return failure
    }
}

// MARK: - SnapshotTesting + Extensions

private extension PreviewDevice {
    func snapshotDevice() -> ViewImageConfig? {
        switch rawValue {
        case "iPhone 16", "iPhone 15", "iPhone 14", "iPhone 13", "iPhone 12", "iPhone 11", "iPhone 10":
            return .iPhoneX
        case "iPhone 6", "iPhone 6s", "iPhone 7", "iPhone 8":
            return .iPhone8
        case "iPhone 6 Plus", "iPhone 6s Plus", "iPhone 8 Plus":
            return .iPhone8Plus
        case "iPhone SE (1st generation)", "iPhone SE (2nd generation)":
            return .iPhoneSe
        case "iPad":
            return .iPad10_2
        case "iPad Mini":
            return .iPadMini
        case "iPad Pro 11":
            return .iPadPro11
        case "iPad Pro 12.9":
            return .iPadPro12_9
        default: return nil
        }
    }
}

private extension Snapshotting where Value: SwiftUI.View, Format == UIImage {
    static func prefireImage(drawHierarchyInKeyWindow: Bool = false,
                             precision: @escaping () -> Float,
                             perceptualPrecision: @escaping () -> Float,
                             duration: @escaping () -> TimeInterval,
                             layout: SwiftUISnapshotLayout = .sizeThatFits,
                             traits: UITraitCollection = .init()) -> Snapshotting {
        let config: ViewImageConfig

        switch layout {
        #if os(iOS) || os(tvOS)
        case let .device(config: deviceConfig):
            config = deviceConfig
        #endif
        case .sizeThatFits:
            // Make sure to use the workaround safe area insets.
            config = .init(safeArea: .one, size: nil, traits: traits)
        case let .fixed(width: width, height: height):
            let size = CGSize(width: width, height: height)
            // Make sure to use the workaround safe area insets.
            config = .init(safeArea: .one, size: size, traits: traits)
        }

        return SimplySnapshotting<UIImage>(pathExtension: "png", diffing: .prefireImage(precision: precision, perceptualPrecision: perceptualPrecision, scale: traits.displayScale))
            .asyncPullback { view in
                var config = config

                let controller: UIViewController

                if config.size != nil {
                    controller = UIHostingController(rootView: view)
                } else {
                    let hostingController = UIHostingController(rootView: view)

                    let maxSize = CGSize.zero
                    config.size = hostingController.sizeThatFits(in: maxSize)

                    controller = hostingController
                }

                return Async<UIImage> { callback in
                    let strategy = snapshotView(config: config,
                                                drawHierarchyInKeyWindow: drawHierarchyInKeyWindow,
                                                traits: traits,
                                                view: controller.view,
                                                viewController: controller)

                    let duration = duration()
                    if duration != .zero {
                        let expectation = XCTestExpectation(description: "Wait")
                        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                            expectation.fulfill()
                        }
                        _ = XCTWaiter.wait(for: [expectation], timeout: duration + 1)
                    }
                    strategy.run(callback)
                }
            }
    }
}

private extension Diffing where Value == UIImage {
    static func prefireImage(precision: @escaping () -> Float, perceptualPrecision: @escaping () -> Float, scale: CGFloat?) -> Diffing {
        lazy var originalDiffing = Diffing.image(precision: precision(), perceptualPrecision: 0.98, scale: scale)
        return Diffing(toData: { originalDiffing.toData($0) },
                       fromData: { originalDiffing.fromData($0) },
                       diff: { originalDiffing.diff($0, $1) })
    }
}

private extension UIEdgeInsets {
    /// A custom inset that prevents the snapshotting library from rendering the
    /// origin at (10000, 10000) which breaks some of our views such as MessageText.
    static var one: UIEdgeInsets { UIEdgeInsets(top: 1, left: 1, bottom: 1, right: 1) }
}

//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI
import XCTest

@testable import ElementX
@testable import SnapshotTesting

@MainActor
class PreviewTests: XCTestCase {
    private struct SnapshotDevice {
        let name: String
        let device: String
    }
    
    private let deviceConfig: ViewImageConfig = .iPhoneX
    private let simulatorDevice: String? = "iPhone14,6" // iPhone SE 3rd Generation
    private let requiredOSVersion = (major: 26, minor: 1)
    // The key is the name we will give to the snapshot
    // The value is the actual device that will be used to render the preview
    private let snapshotDevices: [SnapshotDevice] = [.init(name: "iPhone", device: "iPhone 17"),
                                                     .init(name: "iPad", device: "iPad")]
    private var recordMode: SnapshotTestingConfiguration.Record = .missing

    override func setUp() {
        super.setUp()
        
        if ProcessInfo().environment["RECORD_FAILURES"].map(Bool.init) == true {
            recordMode = .failed
        }

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

    func assertSnapshots(matching preview: _Preview, testName: String = #function, step: Int) async throws {
        let preferences = SnapshotPreferences()
        
        let preferenceReadingView = preview.content
            .onPreferenceChange(SnapshotPrecisionPreferenceKey.self) { preferences.precision = $0 }
            .onPreferenceChange(SnapshotPerceptualPrecisionPreferenceKey.self) { preferences.perceptualPrecision = $0 }
            .onPreferenceChange(SnapshotFulfillmentPreferenceKey.self) { preferences.fulfillmentSource = $0?.source }
        
        // Render an image of the view in order to trigger the preference updates to occur.
        let imageRenderer = ImageRenderer(content: preferenceReadingView)
        _ = imageRenderer.uiImage
        
        switch preferences.fulfillmentSource {
        case .publisher(let publisher):
            let deferred = deferFulfillment(publisher) { $0 == true }
            try await deferred.fulfill()
        case .sequence(let sequence):
            let deferred = deferFulfillment(sequence) { $0 == true }
            try await deferred.fulfill()
        case .none:
            break
        }
        
        var sanitizedSuiteName = String(testName.suffix(testName.count - "test".count).dropLast(2))
        sanitizedSuiteName = sanitizedSuiteName.prefix(1).lowercased() + sanitizedSuiteName.dropFirst()
        
        for snapshotDevice in snapshotDevices {
            guard var device = PreviewDevice(rawValue: snapshotDevice.device).snapshotDevice() else {
                fatalError("Unknown device name: \(snapshotDevice.device)")
            }
            // Ignore specific device safe area (using the workaround value to fix rendering issues).
            device.safeArea = .one
            // Ignore specific device display scale
            let traits = UITraitCollection(displayScale: 2.0)
            
            var testName = ""
            if let displayName = preview.displayName {
                testName = "\(displayName)-\(snapshotDevice.name)-\(localeCode)"
            } else {
                testName = "\(snapshotDevice.name)-\(localeCode)-\(step)"
            }
            
            let isScreen = switch preview.layout {
            case .device: true
            default: false
            }
            if let failure = assertSnapshots(matching: preview.content,
                                             name: testName,
                                             isScreen: isScreen,
                                             device: device,
                                             testName: sanitizedSuiteName,
                                             traits: traits,
                                             preferences: preferences) {
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
                                 name: String?,
                                 isScreen: Bool,
                                 device: ViewImageConfig,
                                 testName: String = #function,
                                 traits: UITraitCollection = .init(),
                                 preferences: SnapshotPreferences) -> String? {
        let matchingView = isScreen ? AnyView(view) : AnyView(view
            .frame(width: device.size?.width)
            .fixedSize(horizontal: false, vertical: true)
        )
        
        return withSnapshotTesting(record: recordMode) {
            verifySnapshot(of: matchingView,
                           as: .prefireImage(preferences: preferences,
                                             layout: isScreen ? .device(config: device) : .sizeThatFits,
                                             traits: traits),
                           named: name,
                           testName: testName)
        }
    }
    
    private func wait(for duration: TimeInterval) {
        let expectation = XCTestExpectation(description: "Wait")
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            expectation.fulfill()
        }
        _ = XCTWaiter.wait(for: [expectation], timeout: duration + 1)
    }
}

private class SnapshotPreferences: @unchecked Sendable {
    var precision: Float = 1
    var perceptualPrecision: Float = 1
    var fulfillmentSource: SnapshotFulfillmentPreferenceKey.Source?
}

// MARK: - SnapshotTesting + Extensions

private extension PreviewDevice {
    func snapshotDevice() -> ViewImageConfig? {
        switch rawValue {
        case "iPhone 17", "iPhone 16", "iPhone 15", "iPhone 14", "iPhone 13", "iPhone 12", "iPhone 11", "iPhone 10":
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
                             preferences: SnapshotPreferences,
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

        return SimplySnapshotting<UIImage>(pathExtension: "png", diffing: .prefireImage(preferences: preferences, scale: traits.displayScale))
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
                
                return snapshotView(config: config,
                                    drawHierarchyInKeyWindow: drawHierarchyInKeyWindow,
                                    traits: traits,
                                    view: controller.view,
                                    viewController: controller)
            }
    }
}

private extension Diffing where Value == UIImage {
    static func prefireImage(preferences: SnapshotPreferences, scale: CGFloat?) -> Diffing {
        lazy var originalDiffing = Diffing.image(precision: preferences.precision, perceptualPrecision: preferences.perceptualPrecision, scale: scale)
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

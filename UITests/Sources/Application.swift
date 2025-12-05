//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import SnapshotTesting
import XCTest

enum Application {
    static func launch(_ identifier: UITestsScreenIdentifier, disableTimelineAccessibility: Bool = true) -> XCUIApplication {
        if ProcessInfo().environment["RECORD_FAILURES"].map(Bool.init) == true {
            XCUIApplication.recordMode = .failed
        }
        
        checkEnvironments()
        
        let app = XCUIApplication()
        
        var launchEnvironment = [
            "UI_TESTS_SCREEN": identifier.rawValue
        ]
        
        if disableTimelineAccessibility {
            launchEnvironment["UI_TESTS_DISABLE_TIMELINE_ACCESSIBILITY"] = "1"
        }
        
        app.launchEnvironment = launchEnvironment
        app.launch()
        return app
    }
    
    private static func checkEnvironments() {
        let requirediPhoneSimulator = "iPhone18,3" // iPhone 17
        let requirediPadSimulator = "iPad15,7" // iPad (A16)
        let requiredOSVersion = (major: 26, minor: 1)
        
        let osVersion = ProcessInfo().operatingSystemVersion
        guard osVersion.majorVersion == requiredOSVersion.major, osVersion.minorVersion == requiredOSVersion.minor else {
            fatalError("Switch to iOS \(requiredOSVersion.major).\(requiredOSVersion.minor) for these tests.")
        }
        
        guard let deviceModel = ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] else {
            fatalError("Unknown simulator.")
        }
        guard deviceModel == requirediPhoneSimulator || deviceModel == requirediPadSimulator else {
            fatalError("Running on \(deviceModel) but we only support \(requirediPhoneSimulator) and \(requirediPadSimulator).")
        }
    }
}

extension XCUIApplication {
    static var recordMode: SnapshotTestingConfiguration.Record = .missing
    
    /// Assert screenshot for a screen with the given identifier. Does not fail if a screenshot is newly created.
    /// - Parameter testName: The current test name, first part of the resulting snapshot filename.
    /// - Parameter step: An optional integer that can be used to take multiple snapshots per test identifier
    /// - Parameter delay: How much to wait before taking the snapshot
    @MainActor
    func assertScreenshot(fileName: String = #file, testName: String = #function, step: Int? = nil, delay: Duration = .seconds(0.5)) async throws {
        // Sometimes the CI might be too slow to load the content so let's wait the delay time
        try await Task.sleep(for: delay)
        
        let snapshot = screenshot().image
        
        var sanitizedSuiteName = String(fileName.prefix(fileName.count - "Tests.swift".count))
        sanitizedSuiteName = (sanitizedSuiteName as NSString).lastPathComponent
        sanitizedSuiteName = sanitizedSuiteName.prefix(1).lowercased() + sanitizedSuiteName.dropFirst()
        
        var testName = "\(testName.dropLast(2))-\(deviceName)-\(localeCode)"
        if let step {
            testName += "-\(step)"
        }
        
        let failure = withSnapshotTesting(record: Self.recordMode) {
            verifySnapshot(of: snapshot,
                           as: .image(precision: 0.99,
                                      perceptualPrecision: 0.98,
                                      scale: nil),
                           named: testName,
                           testName: sanitizedSuiteName)
        }
        
        if let failure {
            XCTFail(failure)
        }
    }
    
    private var deviceName: String {
        switch UIDevice.current.userInterfaceIdiom {
        case .pad: return "iPad"
        case .phone: return "iPhone"
        default: fatalError("Unsupported device type: \(UIDevice.current.userInterfaceIdiom)")
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
}

private extension UIImage {
    /// Adjusts the image by cropping it with the given edge insets.
    func inset(by insets: UIEdgeInsets) -> UIImage {
        let insetRect = CGRect(origin: .zero, size: size).inset(by: insets)
        let renderer = UIGraphicsImageRenderer(size: insetRect.size)
        
        return renderer.image { _ in
            draw(at: CGPoint(x: -insets.left, y: -insets.top))
        }
    }
}

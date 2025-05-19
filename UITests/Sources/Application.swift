//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
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
        let requirediPhoneSimulator = "iPhone17,3" // iPhone 16
        let requirediPadSimulator = "iPad13,18" // iPad (10th generation)
        let requiredOSVersion = 18
        
        let osVersion = ProcessInfo().operatingSystemVersion
        guard osVersion.majorVersion == requiredOSVersion else {
            fatalError("Switch to iOS \(requiredOSVersion) for these tests.")
        }
        
        guard let deviceModel = ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] else {
            fatalError("Unknown simulator.")
        }
        guard deviceModel == requirediPhoneSimulator || deviceModel == requirediPadSimulator else {
            fatalError("Running on \(deviceModel) but we only support \(requirediPhoneSimulator) and \(requirediPadSimulator).")
        }
        guard UIDevice.current.snapshotName == "iPhone-18.4" || UIDevice.current.snapshotName == "iPad-18.4" else {
            fatalError("Running on a simulator that hasn't been renamed to match the expected snapshot filenames.")
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
        UIDevice.current.snapshotName
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

private extension UIDevice {
    var snapshotName: String {
        var name = name
        
        // When running with parallel execution simulators are named "Clone 2 of iPhone 14" etc.
        // Tidy this prefix out of the name to generate snapshots with the correct name.
        if name.starts(with: "Clone "), let range = name.range(of: " of ") {
            name = String(name[range.upperBound...])
        }
        
        return name
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

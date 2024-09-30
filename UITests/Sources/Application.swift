//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
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
    }
}

extension XCUIApplication {
    static var recordMode: SnapshotTestingConfiguration.Record = .missing
    
    @MainActor
    /// Assert screenshot for a screen with the given identifier. Does not fail if a screenshot is newly created.
    /// - Parameter identifier: Identifier of the UI test screen
    /// - Parameter step: An optional integer that can be used to take multiple snapshots per test identifier.
    /// - Parameter insets: Optional insets with which to crop the image by.
    func assertScreenshot(_ identifier: UITestsScreenIdentifier, step: Int? = nil, insets: UIEdgeInsets? = nil, delay: Duration = .seconds(1), precision: Float = 0.99) async throws {
        var snapshotName = identifier.rawValue
        if let step {
            snapshotName += "-\(step)"
        }
        
        snapshotName += "-\(deviceName)-\(localeCode)"

        // Sometimes the CI might be too slow to load the content so let's wait the delay time
        try await Task.sleep(for: delay)
        
        var snapshot = screenshot().image
        
        if let insets {
            snapshot = snapshot.inset(by: insets)
        }

        let failure = withSnapshotTesting(record: Self.recordMode) {
            verifySnapshot(of: snapshot,
                           as: .image(precision: precision,
                                      perceptualPrecision: 0.98,
                                      scale: nil),
                           // use any kind of suffix here to snapshot the same file multiple times and avoid countering on the library side
                           named: "UI",
                           testName: snapshotName)
        }
        
        if let failure {
            XCTFail(failure)
        }
    }
    
    private var deviceName: String {
        var name = UIDevice.current.name
        
        // When running with parallel execution simulators are named "Clone 2 of iPhone 14" etc.
        // Tidy this prefix out of the name to generate snapshots with the correct name.
        if name.starts(with: "Clone "), let range = name.range(of: " of ") {
            name = String(name[range.upperBound...])
        }
        
        return name
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

//
// Copyright 2022 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import SnapshotTesting
import XCTest

struct Application {
    static func launch(_ identifier: UITestsScreenIdentifier, disableTimelineAccessibility: Bool = true) -> XCUIApplication {
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
}

extension XCUIApplication {
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

        // Sometimes the CI might be too slow to load the content so let's wait the delay time
        try await Task.sleep(for: delay)
        
        var snapshot = screenshot().image
        
        if let insets {
            snapshot = snapshot.inset(by: insets)
        }

        let failure = verifySnapshot(matching: snapshot,
                                     as: .image(precision: precision,
                                                perceptualPrecision: 0.98,
                                                scale: nil),
                                     named: snapshotName,
                                     testName: testName)

        if let failure,
           !failure.contains("No reference was found on disk."),
           !failure.contains("to test against the newly-recorded snapshot") {
            XCTFail(failure)
        }
    }

    private var testName: String {
        localeCode + "-" + deviceName
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

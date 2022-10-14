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
    static func launch() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment = ["IS_RUNNING_UI_TESTS": "1"]
        Bundle.elementFallbackLanguage = "en"
        app.launch()
        return app
    }
}

extension XCUIApplication {
    func goToScreenWithIdentifier(_ identifier: UITestScreenIdentifier) {
        let button = buttons[identifier.rawValue]
        let lastLabel = staticTexts["lastItem"]
        
        while !button.isHittable, !lastLabel.isHittable {
            tables.firstMatch.swipeUp()
        }
        
        button.tap()
    }

    /// Assert screenshot for a screen with the given identifier. Does not fail if a screenshot is newly created.
    /// - Parameter identifier: Identifier of the UI test screen
    func assertScreenshot(_ identifier: UITestScreenIdentifier) {
        let failure = verifySnapshot(matching: screenshot().image,
                                     as: .image(precision: 0.98, perceptualPrecision: 0.98, scale: nil),
                                     named: identifier.rawValue,
                                     testName: testName)

        if let failure,
           !failure.contains("No reference was found on disk."),
           !failure.contains("to test against the newly-recorded snapshot") {
            XCTFail(failure)
        }
    }

    private var testName: String {
        osVersion + "-" + languageCode + "-" + regionCode + "-" + deviceName
    }

    private var deviceName: String {
        UIDevice.current.name
    }

    private var languageCode: String {
        Locale.current.languageCode ?? ""
    }

    private var regionCode: String {
        Locale.current.regionCode ?? ""
    }

    private var osVersion: String {
        UIDevice.current.systemVersion.replacingOccurrences(of: ".", with: "-")
    }
}

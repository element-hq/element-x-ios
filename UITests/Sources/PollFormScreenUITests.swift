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

import XCTest

@MainActor
class PollFormScreenUITests: XCTestCase {
    func testEmptyScreen() async throws {
        let app = Application.launch(.createPoll)
        try await app.assertScreenshot(.createPoll)
    }

    func testFilledPoll() async throws {
        let app = Application.launch(.createPoll)
        let questionTextField = app.textViews[A11yIdentifiers.pollFormScreen.question]
        questionTextField.coordinate(withNormalizedOffset: .init(dx: 0.5, dy: 0.5)).tap() // Tap isn't registered without the offset.
        questionTextField.typeText("Do you like polls?")

        let option1TextField = app.textFields[A11yIdentifiers.pollFormScreen.optionID(0)]
        option1TextField.tap()
        option1TextField.typeText("Yes")

        let option2TextField = app.textFields[A11yIdentifiers.pollFormScreen.optionID(1)]
        option2TextField.tap()
        option2TextField.typeText("No\n")

        let createButton = app.buttons[A11yIdentifiers.pollFormScreen.submit]
        XCTAssertTrue(createButton.isEnabled)

        try await app.assertScreenshot(.createPoll, step: 1)
    }

    func testMaxOptions() async throws {
        let app = Application.launch(.createPoll)
        let createButton = app.buttons[A11yIdentifiers.pollFormScreen.submit]
        let addOption = app.buttons[A11yIdentifiers.pollFormScreen.addOption]

        for _ in 1...18 {
            // Make sure the button is tappable and than the keyboard is dismissed. This
            // is very slow but seemingly everything else fails in some subtle way across
            // the various configurations that get run on CI.
            app.swipeUp()
            
            addOption.tap()
        }
        
        app.swipeUp() // Dismisses the keyboard.
        app.swipeUp() // Ensures that the bottom is shown.
        
        XCTAssertFalse(addOption.exists)
        XCTAssertFalse(createButton.isEnabled)

        try await app.assertScreenshot(.createPoll, step: 2)
    }
}

//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import XCTest

@MainActor
class PollFormScreenUITests: XCTestCase {
    func testEmptyScreen() async throws {
        let app = Application.launch(.createPoll)
        try await app.assertScreenshot()
    }

    func testFilledPoll() async throws {
        let app = Application.launch(.createPoll)
        let questionTextField = app.textFields[A11yIdentifiers.pollFormScreen.question]
        questionTextField.tap(.center)
        questionTextField.typeText("Do you like polls?")

        let option1TextField = app.textFields[A11yIdentifiers.pollFormScreen.optionID(0)]
        option1TextField.tap(.center)
        option1TextField.typeText("Yes")

        let option2TextField = app.textFields[A11yIdentifiers.pollFormScreen.optionID(1)]
        option2TextField.tap(.center)
        option2TextField.typeText("No")
        
        // Dismiss the keyboard
        app.swipeDown()

        let createButton = app.buttons[A11yIdentifiers.pollFormScreen.submit]
        XCTAssertTrue(createButton.isEnabled)

        try await app.assertScreenshot()
    }

    func testMaxOptions() async throws {
        let app = Application.launch(.createPoll)
        let createButton = app.buttons[A11yIdentifiers.pollFormScreen.submit]
        let addOption = app.buttons[A11yIdentifiers.pollFormScreen.addOption]

        for _ in 1...8 {
            // Use the frame as a fallback to fix the button being obscured by the home indicator.
            if !addOption.isHittable || addOption.frame.maxY > (app.frame.maxY - 20) {
                app.swipeUp()
            }
            addOption.tap()
        }
        
        app.swipeDown() // Dismiss the keyboard so the Add button is always visible.
        
        app.swipeUp() // Ensures that the bottom is shown.
        
        XCTAssertFalse(addOption.exists)
        XCTAssertFalse(createButton.isEnabled)

        try await app.assertScreenshot()
    }
}

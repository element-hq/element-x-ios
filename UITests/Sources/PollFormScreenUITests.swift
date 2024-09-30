//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
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
        questionTextField.forceTap()
        questionTextField.typeText("Do you like polls?")

        let option1TextField = app.textViews[A11yIdentifiers.pollFormScreen.optionID(0)]
        option1TextField.forceTap()
        option1TextField.typeText("Yes")

        let option2TextField = app.textViews[A11yIdentifiers.pollFormScreen.optionID(1)]
        option2TextField.forceTap()
        option2TextField.typeText("No")
        
        // Dismiss the keyboard
        app.swipeDown()

        let createButton = app.buttons[A11yIdentifiers.pollFormScreen.submit]
        XCTAssertTrue(createButton.isEnabled)

        try await app.assertScreenshot(.createPoll, step: 1)
    }

    func testMaxOptions() async throws {
        let app = Application.launch(.createPoll)
        let createButton = app.buttons[A11yIdentifiers.pollFormScreen.submit]
        let addOption = app.buttons[A11yIdentifiers.pollFormScreen.addOption]

        for _ in 1...18 {
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

        try await app.assertScreenshot(.createPoll, step: 2)
    }
}

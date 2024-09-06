//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import XCTest

@MainActor
class UserSessionScreenTests: XCTestCase {
    let firstRoomName = "Foundation 🔭🪐🌌"
    
    func testUserSessionFlows() async throws {
        let app = Application.launch(.userSessionScreen)
        try await app.assertScreenshot(.userSessionScreen, step: 1)

        app.buttons[A11yIdentifiers.homeScreen.roomName(firstRoomName)].tap()
        XCTAssert(app.staticTexts[firstRoomName].waitForExistence(timeout: 5.0))
        try await Task.sleep(for: .seconds(1))
        try await app.assertScreenshot(.userSessionScreen, step: 2)

        app.buttons[A11yIdentifiers.roomScreen.composerToolbar.openComposeOptions].forceTap()
        try await app.assertScreenshot(.userSessionScreen, step: 3)
    }

    func testUserSessionReply() async throws {
        let app = Application.launch(.userSessionScreenReply, disableTimelineAccessibility: false)
        app.buttons[A11yIdentifiers.homeScreen.roomName(firstRoomName)].tap()
        XCTAssert(app.staticTexts[firstRoomName].waitForExistence(timeout: 5.0))
        try await Task.sleep(for: .seconds(1))

        let cell = app.cells.element(boundBy: 1) // Skip the typing indicator cell
        cell.swipeRight(velocity: .fast)

        try await app.assertScreenshot(.userSessionScreenReply)
    }

    func testElementCall() async throws {
        let app = Application.launch(.userSessionScreen)

        app.buttons[A11yIdentifiers.homeScreen.roomName(firstRoomName)].tap()
        XCTAssert(app.staticTexts[firstRoomName].waitForExistence(timeout: 5.0))

        app.buttons[A11yIdentifiers.roomScreen.joinCall].tap()
        
        let textField = app.textFields["Display name"]
        XCTAssert(textField.waitForExistence(timeout: 10))
        
        let joinButton = app.buttons["Join call now"]
        XCTAssert(joinButton.waitForExistence(timeout: 10))
    }
}

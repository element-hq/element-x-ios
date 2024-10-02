//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import XCTest

@MainActor
class ServerSelectionUITests: XCTestCase {
    func testNormalState() async throws {
        // Given the initial server selection screen as a modal.
        let app = Application.launch(.serverSelection)
        
        // Then it should be configured for matrix.org
        try await app.assertScreenshot(.serverSelection, step: 0)
    }

    func testEmptyAddress() async throws {
        // Given the initial server selection screen as a modal.
        let app = Application.launch(.serverSelection)
        
        // When clearing the server address text field.
        app.textFields[A11yIdentifiers.changeServerScreen.server].tap()
        app.textFields[A11yIdentifiers.changeServerScreen.server].buttons.element.tap()
        
        // Then the screen should not allow the user to continue.
        try await app.assertScreenshot(.serverSelection, step: 1)
    }

    func testInvalidAddress() async throws {
        // Given the initial server selection screen as a modal.
        let app = Application.launch(.serverSelection)
        
        // When typing in an invalid homeserver
        app.textFields[A11yIdentifiers.changeServerScreen.server].clearAndTypeText("thisisbad\n") // The tests only accept an address from LoginHomeserver.mockXYZ
        
        // Then an error should be shown and the confirmation button disabled.
        try await app.assertScreenshot(.serverSelection, step: 2)
        XCTAssertFalse(app.buttons[A11yIdentifiers.changeServerScreen.continue].isEnabled, "The continue button should be disabled when there is an error.")
    }
}

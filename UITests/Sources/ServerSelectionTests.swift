//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import XCTest

@MainActor
class ServerSelectionUITests: XCTestCase {
    func testNormalState() async throws {
        // Given the initial server selection screen as a modal.
        let app = Application.launch(.serverSelection)
        
        // Then it should be configured for matrix.org
        try await app.assertScreenshot()
    }

    func testEmptyAddress() async throws {
        // Given the initial server selection screen as a modal.
        let app = Application.launch(.serverSelection)
        
        // When clearing the server address text field.
        app.textFields[A11yIdentifiers.changeServerScreen.server].tap()
        app.textFields[A11yIdentifiers.changeServerScreen.server].buttons.element.tap()
        
        // Then the screen should not allow the user to continue.
        try await app.assertScreenshot()
    }

    func testInvalidAddress() async throws {
        // Given the initial server selection screen as a modal.
        let app = Application.launch(.serverSelection)
        
        // When typing in an invalid homeserver
        app.textFields[A11yIdentifiers.changeServerScreen.server].clearAndTypeText("thisisbad\n", app: app) // The tests only accept an address from LoginHomeserver.mockXYZ
        
        // Then an error should be shown and the confirmation button disabled.
        try await app.assertScreenshot()
        XCTAssertFalse(app.buttons[A11yIdentifiers.changeServerScreen.continue].isEnabled, "The continue button should be disabled when there is an error.")
    }
}

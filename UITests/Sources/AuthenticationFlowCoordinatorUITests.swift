//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import XCTest

@MainActor
class AuthenticationFlowCoordinatorUITests: XCTestCase {
    func testLoginWithPassword() async throws {
        // Given the authentication flow.
        let app = Application.launch(.authenticationFlow)
        
        // Splash Screen: Tap get started button
        app.buttons[A11yIdentifiers.authenticationStartScreen.signIn].tap()
        
        // Server Confirmation: Tap continue button
        app.buttons[A11yIdentifiers.serverConfirmationScreen.continue].tap()
        
        // Login Screen: Wait for continue button to appear
        let continueButton = app.buttons[A11yIdentifiers.loginScreen.continue]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 2.0))
        
        // Login Screen: Enter valid credentials
        app.textFields[A11yIdentifiers.loginScreen.emailUsername].clearAndTypeText("alice\n")
        app.secureTextFields[A11yIdentifiers.loginScreen.password].clearAndTypeText("12345678")

        try await app.assertScreenshot(.authenticationFlow)
        
        // Login Screen: Tap next
        app.buttons[A11yIdentifiers.loginScreen.continue].tap()
    }
    
    func testLoginWithIncorrectPassword() async throws {
        // Given the authentication flow.
        let app = Application.launch(.authenticationFlow)
        
        // Splash Screen: Tap get started button
        app.buttons[A11yIdentifiers.authenticationStartScreen.signIn].tap()
        
        // Server Confirmation: Tap continue button
        app.buttons[A11yIdentifiers.serverConfirmationScreen.continue].tap()
        
        // Login Screen: Wait for continue button to appear
        let continueButton = app.buttons[A11yIdentifiers.loginScreen.continue]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 2.0))
        
        // Login Screen: Enter invalid credentials
        app.textFields[A11yIdentifiers.loginScreen.emailUsername].clearAndTypeText("alice")
        app.secureTextFields[A11yIdentifiers.loginScreen.password].clearAndTypeText("87654321")

        // Login Screen: Tap continue
        XCTAssertTrue(continueButton.isEnabled)
        continueButton.tap()
        
        // Then login should fail.
        XCTAssertTrue(app.alerts.element.waitForExistence(timeout: 2.0), "An error alert should be shown when attempting login with invalid credentials.")
    }
    
    func testLoginWithUnsupportedUserID() async throws {
        // Given the authentication flow.
        let app = Application.launch(.authenticationFlow)
        
        // Splash Screen: Tap get started button
        app.buttons[A11yIdentifiers.authenticationStartScreen.signIn].tap()
        
        // Server Confirmation: Tap continue button
        app.buttons[A11yIdentifiers.serverConfirmationScreen.continue].tap()
        
        // Login Screen: Wait for continue button to appear
        let continueButton = app.buttons[A11yIdentifiers.loginScreen.continue]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 2.0))
        
        // When entering a username on a homeserver with an unsupported flow.
        app.textFields[A11yIdentifiers.loginScreen.emailUsername].clearAndTypeText("@test:server.net\n")
        
        // Then the screen should not allow login to continue.
        try await app.assertScreenshot(.authenticationFlow, step: 1)
    }
    
    func testSelectingOIDCServer() {
        // Given the authentication flow.
        let app = Application.launch(.authenticationFlow)
        
        // Splash Screen: Tap get started button
        app.buttons[A11yIdentifiers.authenticationStartScreen.signIn].tap()
        
        // Server Confirmation: Tap change server button
        app.buttons[A11yIdentifiers.serverConfirmationScreen.changeServer].tap()
        
        // Server Selection: Clear the default, enter OIDC server and continue.
        app.textFields[A11yIdentifiers.changeServerScreen.server].clearAndTypeText("company.com\n")
        
        // Server Confirmation: Tap continue button
        app.buttons[A11yIdentifiers.serverConfirmationScreen.continue].tap()
        
        // Then the login form shouldn't be shown as OIDC will be used instead.
        XCTAssertFalse(app.buttons[A11yIdentifiers.loginScreen.continue].waitForExistence(timeout: 1), "The login screen should not be shown after selecting a homeserver with OIDC.")
    }
}

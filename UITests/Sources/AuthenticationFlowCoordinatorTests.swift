//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import XCTest

@MainActor
class AuthenticationFlowCoordinatorUITests: XCTestCase {
    func testLoginWithPassword() async throws {
        // Given the authentication flow.
        let app = Application.launch(.authenticationFlow)
        
        // Check the bug report flow works.
        try await verifyReportBugButton(app)
        
        // Splash Screen: Tap get started button
        app.buttons[A11yIdentifiers.authenticationStartScreen.signIn].tap()
        
        // Server Confirmation: Tap change server button
        app.buttons[A11yIdentifiers.serverConfirmationScreen.changeServer].tap()
        
        // Server Selection: Clear the default, enter OIDC server and continue.
        app.textFields[A11yIdentifiers.changeServerScreen.server].clearAndTypeText("example.com\n", app: app)
        
        // Await for the button to be hittable, since a loader may appear
        let serverConfirmationContinueButton = app.buttons[A11yIdentifiers.serverConfirmationScreen.continue]
        XCTAssertTrue(serverConfirmationContinueButton.wait(for: \.isHittable, toEqual: true, timeout: 2.0))
        // Server Confirmation: Tap continue button
        serverConfirmationContinueButton.tap()
        
        // Login Screen: Wait for continue button to appear
        let continueButton = app.buttons[A11yIdentifiers.loginScreen.continue]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 2.0))
        
        // Login Screen: Enter valid credentials
        app.textFields[A11yIdentifiers.loginScreen.emailUsername].clearAndTypeText("alice\n", app: app)
        app.secureTextFields[A11yIdentifiers.loginScreen.password].clearAndTypeText("12345678", app: app)

        try await app.assertScreenshot()
        
        // Login Screen: Tap next
        app.buttons[A11yIdentifiers.loginScreen.continue].tap()
    }
    
    func testLoginWithIncorrectPassword() {
        // Given the authentication flow.
        let app = Application.launch(.authenticationFlow)
        
        // Splash Screen: Tap get started button
        app.buttons[A11yIdentifiers.authenticationStartScreen.signIn].tap()
        
        // Server Confirmation: Tap change server button
        app.buttons[A11yIdentifiers.serverConfirmationScreen.changeServer].tap()
        
        // Server Selection: Clear the default, enter OIDC server and continue.
        app.textFields[A11yIdentifiers.changeServerScreen.server].clearAndTypeText("example.com\n", app: app)
        
        // Await for the button to be hittable, since a loader may appear
        let serverConfirmationContinueButton = app.buttons[A11yIdentifiers.serverConfirmationScreen.continue]
        XCTAssertTrue(serverConfirmationContinueButton.wait(for: \.isHittable, toEqual: true, timeout: 2.0))
        // Server Confirmation: Tap continue button
        serverConfirmationContinueButton.tap()
        
        // Login Screen: Wait for continue button to appear
        let continueButton = app.buttons[A11yIdentifiers.loginScreen.continue]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 2.0))
        
        // Login Screen: Enter invalid credentials
        app.textFields[A11yIdentifiers.loginScreen.emailUsername].clearAndTypeText("alice", app: app)
        app.secureTextFields[A11yIdentifiers.loginScreen.password].clearAndTypeText("87654321", app: app)

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
        
        // Server Confirmation: Tap change server button
        app.buttons[A11yIdentifiers.serverConfirmationScreen.changeServer].tap()
        
        // Server Selection: Clear the default, enter OIDC server and continue.
        app.textFields[A11yIdentifiers.changeServerScreen.server].clearAndTypeText("example.com\n", app: app)
        
        // Await for the button to be hittable, since a loader may appear
        let serverConfirmationContinueButton = app.buttons[A11yIdentifiers.serverConfirmationScreen.continue]
        XCTAssertTrue(serverConfirmationContinueButton.wait(for: \.isHittable, toEqual: true, timeout: 2.0))
        // Server Confirmation: Tap continue button
        serverConfirmationContinueButton.tap()
        
        // Login Screen: Wait for continue button to appear
        let continueButton = app.buttons[A11yIdentifiers.loginScreen.continue]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 2.0))
        
        // When entering a username on a homeserver with an unsupported flow.
        app.textFields[A11yIdentifiers.loginScreen.emailUsername].clearAndTypeText("@test:server.net\n", app: app)
        
        // Then the screen should not allow login to continue.
        try await app.assertScreenshot()
    }
    
    /// Disabled for now as the looping isn't 100% fool-proof and we have OIDC on the integration tests
    /// so this mock version doesn't really add anything to the tests as a whole.
    func disabled_testSelectingOIDCServer() {
        // Allow this test to run for longer to help with the loop whilst waiting to resolve the
        // webcredentials for the Web Authentication Session (see below).
        executionTimeAllowance = 300
        
        // Given the authentication flow.
        let app = Application.launch(.authenticationFlow)
        
        // Splash Screen: Tap get started button
        app.buttons[A11yIdentifiers.authenticationStartScreen.signIn].tap()
        
        // Server Confirmation: Tap change server button
        app.buttons[A11yIdentifiers.serverConfirmationScreen.changeServer].tap()
        
        // Server Selection: Clear the default, enter OIDC server and continue.
        app.textFields[A11yIdentifiers.changeServerScreen.server].clearAndTypeText("company.com\n", app: app)
        
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let wasAlertText = springboard.staticTexts["“ElementX” Wants to Use “company.com” to Sign In"]
        
        // On a fresh simulator the webcredentials association is sometimes slow to be resolved.
        // This results in an error alert being shown instead of the Web Authentication Session alert.
        // Keep looping on the Continue button for ~5 minutes until the Authentication Session is happy.
        var remainingAttempts = 30
        while !wasAlertText.exists {
            // Server Confirmation: Tap continue button
            app.buttons[A11yIdentifiers.serverConfirmationScreen.continue].tap()
            
            if wasAlertText.waitForExistence(timeout: 10) {
                break
            }
            
            remainingAttempts -= 1
            if remainingAttempts <= 0 {
                XCTFail("Failed to present the web authentication session.")
            }
            
            if app.alerts.count > 0 {
                app.alerts.firstMatch.buttons["OK"].tap()
            }
        }
        
        XCTAssertTrue(wasAlertText.exists, "The web authentication prompt should be shown after selecting a homeserver with OIDC.")
    }
    
    func testProvisionedLoginWithPassword() async throws {
        // Given a provisioned authentication flow.
        let app = Application.launch(.provisionedAuthenticationFlow)
        
        // Then the start screen should be configured appropriately.
        try await app.assertScreenshot()
        
        // Check the bug report flow works.
        try await verifyReportBugButton(app)
        
        // Splash Screen: Tap get started button
        app.buttons[A11yIdentifiers.authenticationStartScreen.signIn].tap()
        
        // No server selection should be shown here
        
        // Login Screen: Wait for continue button to appear
        let continueButton = app.buttons[A11yIdentifiers.loginScreen.continue]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 2.0))
        
        // Login Screen: Enter valid credentials
        app.textFields[A11yIdentifiers.loginScreen.emailUsername].clearAndTypeText("alice\n", app: app)
        app.secureTextFields[A11yIdentifiers.loginScreen.password].clearAndTypeText("12345678", app: app)
        
        // Login Screen: Tap next
        app.buttons[A11yIdentifiers.loginScreen.continue].tap()
    }
    
    func testSingleProviderLoginWithPassword() async throws {
        // Given the authentication flow with a single supported server.
        let app = Application.launch(.singleProviderAuthenticationFlow)
        
        // Then the start screen should be configured appropriately.
        try await app.assertScreenshot()
        
        // Check the bug report flow works.
        try await verifyReportBugButton(app)
        
        // Splash Screen: Tap get started button
        app.buttons[A11yIdentifiers.authenticationStartScreen.signIn].tap()
        
        // No server selection should be shown here
        
        // Login Screen: Wait for continue button to appear
        let continueButton = app.buttons[A11yIdentifiers.loginScreen.continue]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 2.0))
        
        // Login Screen: Enter valid credentials
        app.textFields[A11yIdentifiers.loginScreen.emailUsername].clearAndTypeText("alice\n", app: app)
        app.secureTextFields[A11yIdentifiers.loginScreen.password].clearAndTypeText("12345678", app: app)
        
        // Login Screen: Tap next
        app.buttons[A11yIdentifiers.loginScreen.continue].tap()
    }
    
    func testMultipleProvidersLoginWithPassword() async throws {
        // Given the authentication flow with only 2 allowed servers.
        let app = Application.launch(.multipleProvidersAuthenticationFlow)
        
        // Then the start screen should be configured appropriately.
        try await app.assertScreenshot()
        
        // Splash Screen: Tap get started button
        app.buttons[A11yIdentifiers.authenticationStartScreen.signIn].tap()
        
        // Server Confirmation: Tap the picker and confirm
        app.switches.matching(identifier: A11yIdentifiers.serverConfirmationScreen.serverPicker).element(boundBy: 1).tap()
        app.buttons[A11yIdentifiers.serverConfirmationScreen.continue].tap()
        
        // Login Screen: Wait for continue button to appear
        let continueButton = app.buttons[A11yIdentifiers.loginScreen.continue]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 2.0))
        
        // Login Screen: Enter valid credentials
        app.textFields[A11yIdentifiers.loginScreen.emailUsername].clearAndTypeText("alice\n", app: app)
        app.secureTextFields[A11yIdentifiers.loginScreen.password].clearAndTypeText("12345678", app: app)
        
        // Login Screen: Tap next
        app.buttons[A11yIdentifiers.loginScreen.continue].tap()
    }
    
    func verifyReportBugButton(_ app: XCUIApplication) async throws {
        // Splash Screen: Tap the version 7 times to report a problem
        app.staticTexts[A11yIdentifiers.authenticationStartScreen.appVersion].tap(withNumberOfTaps: 7, numberOfTouches: 1)
        
        // Bug report: Make sure it exists then cancel.
        XCTAssert(app.textFields[A11yIdentifiers.bugReportScreen.report].exists)
        app.buttons[A11yIdentifiers.bugReportScreen.cancel].tap()
    }
}

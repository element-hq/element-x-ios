//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import XCTest

@MainActor
class RootFlowCoordinatorUITests: XCTestCase {
    func testSignIn() {
        let app = Application.launch(.rootFlow)
        
        app.buttons[A11yIdentifiers.authenticationStartScreen.signIn].tap()
        
        // The \n confirms the server, navigating to the login screen.
        app.textFields[A11yIdentifiers.changeServerScreen.server].clearAndTypeText("example.com\n", app: app)
        
        let continueButton = app.buttons[A11yIdentifiers.loginScreen.continue]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 2.0))
        
        app.textFields[A11yIdentifiers.loginScreen.emailUsername].clearAndTypeText("alice\n", app: app)
        app.secureTextFields[A11yIdentifiers.loginScreen.password].clearAndTypeText("12345678", app: app)
        continueButton.tap()
        
        XCTAssertTrue(app.buttons[A11yIdentifiers.homeScreen.userAvatar].waitForExistence(timeout: 5.0),
                      "Signing in should replace the authentication flow with the user session flow.")
    }
    
    func testSignOut() {
        let app = Application.launch(.rootFlowSignedIn)
        
        // `Failed to scroll to visible (by AX action) Button` https://stackoverflow.com/a/33534187/730924
        app.buttons[A11yIdentifiers.homeScreen.userAvatar].tap(.center)
        XCTAssertTrue(app.staticTexts["@mock:client.com"].waitForExistence(timeout: 2.0))
        signOut(app)
        
        let userAvatar = app.buttons[A11yIdentifiers.homeScreen.userAvatar]
        XCTAssertTrue(userAvatar.waitForExistence(timeout: 5.0))
        userAvatar.tap(.center)
        XCTAssertTrue(app.staticTexts["@bob:client.com"].waitForExistence(timeout: 2.0),
                      "Signing out should replace the user session flow with the next account's.")
        signOut(app)
        
        XCTAssertTrue(app.buttons[A11yIdentifiers.authenticationStartScreen.signIn].waitForExistence(timeout: 5.0),
                      "Signing out of the last account should replace the user session flow with the authentication flow.")
    }
    
    func testCancelAddingAccount() {
        let app = Application.launch(.rootFlowSignedIn)
        
        // `Failed to scroll to visible (by AX action) Button` https://stackoverflow.com/a/33534187/730924
        app.buttons[A11yIdentifiers.homeScreen.userAvatar].tap(.center)
        
        let addAccountButton = app.buttons[A11yIdentifiers.settingsScreen.addAccount]
        XCTAssertTrue(addAccountButton.waitForExistence(timeout: 2.0))
        addAccountButton.tap()
        
        let cancelButton = app.buttons["Cancel"]
        XCTAssertTrue(cancelButton.waitForExistence(timeout: 2.0))
        cancelButton.tap()
        
        XCTAssertTrue(addAccountButton.waitForExistence(timeout: 5.0),
                      "Cancelling adding an account should return to the settings screen.")
    }
    
    func testSwitchAccount() {
        let app = Application.launch(.rootFlowSignedIn)
        
        // `Failed to scroll to visible (by AX action) Button` https://stackoverflow.com/a/33534187/730924
        app.buttons[A11yIdentifiers.homeScreen.userAvatar].tap(.center)
        XCTAssertTrue(app.staticTexts["@mock:client.com"].waitForExistence(timeout: 2.0))
        
        // The account picker is expanded by default.
        let bobAccount = app.buttons[A11yIdentifiers.settingsScreen.otherAccount("@bob:client.com")]
        XCTAssertTrue(bobAccount.waitForExistence(timeout: 2.0))
        bobAccount.tap()
        
        let userAvatar = app.buttons[A11yIdentifiers.homeScreen.userAvatar]
        XCTAssertTrue(userAvatar.waitForExistence(timeout: 5.0))
        userAvatar.tap(.center)
        XCTAssertTrue(app.staticTexts["@bob:client.com"].waitForExistence(timeout: 2.0),
                      "Switching account should replace the user session flow with the selected account's.")
        XCTAssertTrue(app.buttons[A11yIdentifiers.settingsScreen.otherAccount("@mock:client.com")].exists)
        XCTAssertFalse(app.buttons[A11yIdentifiers.settingsScreen.otherAccount("@bob:client.com")].exists)
    }
    
    func testElementCall() {
        let app = Application.launch(.rootFlowSignedIn)
        
        let roomName = "Foundation 🔭🪐🌌"
        app.buttons[A11yIdentifiers.homeScreen.roomName(roomName)].tap()
        XCTAssert(app.buttons[roomName].waitForExistence(timeout: 5.0))
        
        app.buttons[A11yIdentifiers.roomScreen.joinCall].tap()
        
        let textField = app.textFields["Display name"]
        XCTAssert(textField.waitForExistence(timeout: 10))
        
        let joinButton = app.buttons["Continue"]
        XCTAssert(joinButton.waitForExistence(timeout: 10))
    }
    
    // MARK: - Helpers
    
    /// Signs out of the account whose settings are shown.
    private func signOut(_ app: XCUIApplication) {
        app.swipeUp() // Make sure the sign out button is visible.
        app.buttons[A11yIdentifiers.settingsScreen.logout].tap()
        app.alerts.element.buttons[A11yIdentifiers.alertInfo.primaryButton].firstMatch.tap()
    }
}

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
        
        app.swipeUp() // Make sure the sign out button is visible.
        app.buttons[A11yIdentifiers.settingsScreen.logout].tap()
        app.alerts.element.buttons[A11yIdentifiers.alertInfo.primaryButton].firstMatch.tap()
        
        XCTAssertTrue(app.buttons[A11yIdentifiers.authenticationStartScreen.signIn].waitForExistence(timeout: 5.0),
                      "Signing out should replace the user session flow with the authentication flow.")
    }
}

//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import XCTest

extension XCUIApplication {
    func login(currentTestCase: XCTestCase) {
        let getStartedButton = buttons[A11yIdentifiers.authenticationStartScreen.signIn]
        
        XCTAssertTrue(getStartedButton.waitForExistence(timeout: 10.0))
        getStartedButton.tapCenter()
        
        let changeHomeserverButton = buttons[A11yIdentifiers.serverConfirmationScreen.changeServer]
        XCTAssertTrue(changeHomeserverButton.waitForExistence(timeout: 10.0))
        changeHomeserverButton.tapCenter()
        
        let homeserverTextField = textFields[A11yIdentifiers.changeServerScreen.server]
        XCTAssertTrue(homeserverTextField.waitForExistence(timeout: 10.0))
        
        homeserverTextField.clearAndTypeText(homeserver, app: self)
        
        let confirmButton = buttons[A11yIdentifiers.changeServerScreen.continue]
        XCTAssertTrue(confirmButton.waitForExistence(timeout: 10.0))
        confirmButton.tapCenter()
        
        // Wait for server confirmation to finish
        let doesNotExistPredicate = NSPredicate(format: "exists == 0")
        currentTestCase.expectation(for: doesNotExistPredicate, evaluatedWith: confirmButton)
        currentTestCase.waitForExpectations(timeout: 300.0)
        
        let continueButton = buttons[A11yIdentifiers.serverConfirmationScreen.continue]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 30.0))
        continueButton.tapCenter()
        
        let usernameTextField = textFields[A11yIdentifiers.loginScreen.emailUsername]
        XCTAssertTrue(usernameTextField.waitForExistence(timeout: 10.0))
        
        usernameTextField.clearAndTypeText(username, app: self)
        
        let passwordTextField = secureTextFields[A11yIdentifiers.loginScreen.password]
        XCTAssertTrue(passwordTextField.waitForExistence(timeout: 10.0))
        
        passwordTextField.clearAndTypeText(password, app: self)
        
        let nextButton = buttons[A11yIdentifiers.loginScreen.continue]
        XCTAssertTrue(nextButton.waitForExistence(timeout: 10.0))
        XCTAssertTrue(nextButton.isEnabled)
        
        nextButton.tapCenter()
        
        // Wait for login to finish
        currentTestCase.expectation(for: doesNotExistPredicate, evaluatedWith: usernameTextField)
        currentTestCase.waitForExpectations(timeout: 300.0)
                
        // Handle the password saving dialog
        let savePasswordButton = buttons["Save Password"]
        if savePasswordButton.waitForExistence(timeout: 10.0) {
            // Tapping the sheet button while animating upwards fails. Wait for it to settle
            sleep(1)
            
            savePasswordButton.tapCenter()
        }
                
        // Wait for the home screen to become visible.
        let profileButton = buttons[A11yIdentifiers.homeScreen.userAvatar]
        // Timeouts are huge because we're waiting for the server.
        XCTAssertTrue(profileButton.waitForExistence(timeout: 300.0))
    }
    
    func logout() {
        // On first login when multiple sheets get presented the profile button is not hittable
        // Moving the scroll fixed it for some obscure reason
        swipeDown()
        
        let profileButton = buttons[A11yIdentifiers.homeScreen.userAvatar]
                
        // `Failed to scroll to visible (by AX action) Button` https://stackoverflow.com/a/33534187/730924
        profileButton.tapCenter()
        
        // Logout
        let logoutButton = buttons[A11yIdentifiers.settingsScreen.logout]
        XCTAssertTrue(logoutButton.waitForExistence(timeout: 10.0))
        logoutButton.tapCenter()
        
        // Confirm logout
        let alertLogoutButton = alerts.firstMatch.buttons["Sign out"]
        XCTAssertTrue(alertLogoutButton.waitForExistence(timeout: 10.0))
        alertLogoutButton.tapCenter()
        
        // Check that we're back on the login screen
        let getStartedButton = buttons[A11yIdentifiers.authenticationStartScreen.signIn]
        XCTAssertTrue(getStartedButton.waitForExistence(timeout: 10.0))
    }
}

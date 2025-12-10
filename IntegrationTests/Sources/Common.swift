//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import XCTest

enum IntegrationTestsError: Error {
    case webAuthenticationSessionFailure
}

extension XCUIApplication {
    private var doesNotExistPredicate: NSPredicate { NSPredicate(format: "exists == 0") }
    
    func login(currentTestCase: XCTestCase) throws {
        let getStartedButton = buttons[A11yIdentifiers.authenticationStartScreen.signIn]
        
        XCTAssertTrue(getStartedButton.waitForExistence(timeout: 10.0))
        getStartedButton.tap(.center)
        
        if let homeserver {
            let changeHomeserverButton = buttons[A11yIdentifiers.serverConfirmationScreen.changeServer]
            XCTAssertTrue(changeHomeserverButton.waitForExistence(timeout: 10.0))
            changeHomeserverButton.tap(.center)
            
            let homeserverTextField = textFields[A11yIdentifiers.changeServerScreen.server]
            XCTAssertTrue(homeserverTextField.waitForExistence(timeout: 10.0))
            
            homeserverTextField.clearAndTypeText(homeserver, app: self)
            
            let confirmButton = buttons[A11yIdentifiers.changeServerScreen.continue]
            XCTAssertTrue(confirmButton.waitForExistence(timeout: 10.0))
            confirmButton.tap(.center)
            
            // Wait for server confirmation to finish
            currentTestCase.expectation(for: doesNotExistPredicate, evaluatedWith: confirmButton)
            currentTestCase.waitForExpectations(timeout: 300.0)
        }
        
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let webAuthenticationSessionAlertContinueButton = springboard.buttons["Continue"].firstMatch
        
        // On a fresh simulator the webcredentials association is sometimes slow to be resolved.
        // This results in an error alert being shown instead of the Web Authentication Session alert.
        // Keep looping on the Continue button for ~5 minutes until the Authentication Session is happy.
        var remainingAttempts = 10
        while !webAuthenticationSessionAlertContinueButton.exists {
            let continueButton = buttons[A11yIdentifiers.serverConfirmationScreen.continue]
            XCTAssertTrue(continueButton.waitForExistence(timeout: 30.0))
            continueButton.tap(.center)
            
            if webAuthenticationSessionAlertContinueButton.waitForExistence(timeout: 30.0) {
                break
            }
            
            remainingAttempts -= 1
            if remainingAttempts <= 0 {
                XCTFail("Failed to present the web authentication session.")
                throw IntegrationTestsError.webAuthenticationSessionFailure
            }
            
            if alerts.count > 0 {
                alerts.firstMatch.buttons["OK"].firstMatch.tap()
            }
        }
        
        webAuthenticationSessionAlertContinueButton.tap(.center)
        
        let webAuthenticationView = XCUIApplication(bundleIdentifier: "com.apple.SafariViewService")
        XCTAssertTrue(webAuthenticationView.waitForExistence(timeout: 10.0))
        webAuthenticationView.tap(.top) // Tap the web view to properly focus the app again.
        
        let webUsernameTextField = textFields["Username or Email"]
        XCTAssertTrue(webUsernameTextField.waitForExistence(timeout: 10.0))
        webUsernameTextField.clearAndTypeText(username, app: self)
        webAuthenticationView.buttons["Done"].firstMatch.tap() // Dismiss the keyboard so that the password text field is fully hittable.
        
        let webPasswordTextField = secureTextFields["Password"]
        XCTAssertTrue(webPasswordTextField.waitForExistence(timeout: 10.0))
        webPasswordTextField.clearAndTypeText(password, app: self)
        webAuthenticationView.buttons["Done"].firstMatch.tap() // Dismiss the keyboard so that the continue button is fully hittable.
        
        let webLoginButton = webAuthenticationView.buttons["Continue"]
        XCTAssertTrue(webLoginButton.waitForExistence(timeout: 10.0))
        webLoginButton.tap(.center)
        
        // Handle the password saving dialog
        let savePasswordButton = buttons["Save Password"]
        if savePasswordButton.waitForExistence(timeout: 10.0) {
            // Tapping the sheet button while animating upwards fails. Wait for it to settle
            sleep(1)
            
            buttons["Not Now"].tap(.center)
        }
        
        let webConsentButton = webAuthenticationView.buttons["Continue"]
        XCTAssertTrue(webConsentButton.waitForExistence(timeout: 10.0))
        webConsentButton.tap(.center)
        
        // Wait for login to finish
        currentTestCase.expectation(for: doesNotExistPredicate, evaluatedWith: webUsernameTextField)
        currentTestCase.waitForExpectations(timeout: 300.0)
                
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
        profileButton.tap(.center)
        
        // Make the logout button visible
        swipeUp()
        
        // Logout
        let logoutButton = buttons[A11yIdentifiers.settingsScreen.logout]
        XCTAssertTrue(logoutButton.waitForExistence(timeout: 10.0))
        logoutButton.tap(.center)
        
        // Confirm logout
        let alertLogoutButton = alerts.firstMatch.buttons["Sign out"].firstMatch
        XCTAssertTrue(alertLogoutButton.waitForExistence(timeout: 10.0))
        alertLogoutButton.tap(.center)
        
        // Check that we're back on the login screen
        let getStartedButton = buttons[A11yIdentifiers.authenticationStartScreen.signIn]
        XCTAssertTrue(getStartedButton.waitForExistence(timeout: 10.0))
    }
}

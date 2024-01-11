//
// Copyright 2023 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import XCTest

extension XCUIApplication {
    func login(currentTestCase: XCTestCase) {
        let getStartedButton = buttons[A11yIdentifiers.onboardingScreen.signIn]
        
        XCTAssertTrue(getStartedButton.waitForExistence(timeout: 10.0))
        getStartedButton.tap()
        
        // Get started is network bound, wait for the change homeserver button for longer
        let changeHomeserverButton = buttons[A11yIdentifiers.serverConfirmationScreen.changeServer]
        XCTAssertTrue(changeHomeserverButton.waitForExistence(timeout: 30.0))
        changeHomeserverButton.tap()
        
        let homeserverTextField = textFields[A11yIdentifiers.changeServerScreen.server]
        XCTAssertTrue(homeserverTextField.waitForExistence(timeout: 10.0))
        
        homeserverTextField.clearAndTypeText(homeserver)
        
        let confirmButton = buttons[A11yIdentifiers.changeServerScreen.continue]
        XCTAssertTrue(confirmButton.waitForExistence(timeout: 10.0))
        confirmButton.tap()
        
        // Wait for server confirmation to finish
        let doesNotExistPredicate = NSPredicate(format: "exists == 0")
        currentTestCase.expectation(for: doesNotExistPredicate, evaluatedWith: confirmButton)
        currentTestCase.waitForExpectations(timeout: 300.0)
        
        let continueButton = buttons[A11yIdentifiers.serverConfirmationScreen.continue]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 30.0))
        continueButton.tap()
        
        let usernameTextField = textFields[A11yIdentifiers.loginScreen.emailUsername]
        XCTAssertTrue(usernameTextField.waitForExistence(timeout: 10.0))
        
        usernameTextField.clearAndTypeText(username)
        
        let passwordTextField = secureTextFields[A11yIdentifiers.loginScreen.password]
        XCTAssertTrue(passwordTextField.waitForExistence(timeout: 10.0))
        
        passwordTextField.clearAndTypeText(password)
        
        let nextButton = buttons[A11yIdentifiers.loginScreen.continue]
        XCTAssertTrue(nextButton.waitForExistence(timeout: 10.0))
        XCTAssertTrue(nextButton.isEnabled)
        
        nextButton.tap()
        
        // Wait for login to finish
        currentTestCase.expectation(for: doesNotExistPredicate, evaluatedWith: usernameTextField)
        currentTestCase.waitForExpectations(timeout: 300.0)
        
        // Handle analytics prompt screen
        if staticTexts[A11yIdentifiers.analyticsPromptScreen.title].waitForExistence(timeout: 10.0) {
            // Wait for login and then handle save password sheet
            let savePasswordButton = buttons["Save Password"]
            if savePasswordButton.waitForExistence(timeout: 10.0) {
                savePasswordButton.tap()
            }
            
            let enableButton = buttons[A11yIdentifiers.analyticsPromptScreen.enable]
            XCTAssertTrue(enableButton.waitForExistence(timeout: 10.0))
            enableButton.tap()
        }
        
        // This might come in a different order, wait for both.
        let savePasswordButton = buttons["Save Password"]
        if savePasswordButton.waitForExistence(timeout: 10.0) {
            savePasswordButton.tap()
        }
        
        // Handle the notifications permission alert https://stackoverflow.com/a/58171074/730924
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let notificationAlertDeclineButton = springboard.buttons.element(boundBy: 0)
        if notificationAlertDeclineButton.waitForExistence(timeout: 10.0) {
            notificationAlertDeclineButton.tap()
        }
        
        // Migration screen may be shown as an overlay.
        // if that pops up soon enough, we just let that happen and wait
        let message = staticTexts[A11yIdentifiers.migrationScreen.message]
        
        if message.waitForExistence(timeout: 10.0) {
            currentTestCase.expectation(for: doesNotExistPredicate, evaluatedWith: message)
            currentTestCase.waitForExpectations(timeout: 300.0)
        }
        
        // Welcome screen may be shown as an overlay.
        if buttons[A11yIdentifiers.welcomeScreen.letsGo].waitForExistence(timeout: 1.0) {
            let goButton = buttons[A11yIdentifiers.welcomeScreen.letsGo]
            XCTAssertTrue(goButton.waitForExistence(timeout: 1.0))
            goButton.tap()
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
        profileButton.forceTap()
        
        // Open the settings
        let settingsButton = buttons[A11yIdentifiers.homeScreen.settings]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 10.0))
        settingsButton.tap()
        
        // Logout
        let logoutButton = buttons[A11yIdentifiers.settingsScreen.logout]
        XCTAssertTrue(logoutButton.waitForExistence(timeout: 10.0))
        logoutButton.tap()
        
        // Confirm logout
        let alertLogoutButton = alerts.firstMatch.buttons["Sign out"]
        XCTAssertTrue(alertLogoutButton.waitForExistence(timeout: 10.0))
        alertLogoutButton.tap()
        
        // Check that we're back on the login screen
        let getStartedButton = buttons[A11yIdentifiers.onboardingScreen.signIn]
        XCTAssertTrue(getStartedButton.waitForExistence(timeout: 10.0))
    }
}

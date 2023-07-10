//
// Copyright 2022 New Vector Ltd
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

class LoginTests: XCTestCase {
    func testLoginFlow() throws {
        let parser = TestMeasurementParser()
        parser.capture(testCase: self) {
            let metrics: [XCTMetric] = [
                XCTApplicationLaunchMetric(),
                XCTClockMetric(),
                XCTOSSignpostMetric(subsystem: Signposter.subsystem, category: Signposter.category, name: "\(Signposter.Name.login)"),
                XCTOSSignpostMetric(subsystem: Signposter.subsystem, category: Signposter.category, name: "\(Signposter.Name.sync)"),
                XCTOSSignpostMetric(subsystem: Signposter.subsystem, category: Signposter.category, name: "\(Signposter.Name.roomFlow)")
            ]
            
            self.measure(metrics: metrics) {
                self.runLoginLogoutFlow()
            }
        }
        
        guard let actualDuration = parser.valueForMetric(.clockMonotonicTime) else {
            XCTFail("Couldn't retrieve duration")
            return
        }
    }

    private func runLoginLogoutFlow() {
        let app = Application.launch()
                
        let getStartedButton = app.buttons[A11yIdentifiers.onboardingScreen.signIn]
        
        XCTAssertTrue(getStartedButton.waitForExistence(timeout: 10.0))
        getStartedButton.tap()
        
        let changeHomeserverButton = app.buttons[A11yIdentifiers.serverConfirmationScreen.changeServer]
        XCTAssertTrue(changeHomeserverButton.waitForExistence(timeout: 10.0))
        changeHomeserverButton.tap()
        
        let homeserverTextField = app.textFields[A11yIdentifiers.changeServerScreen.server]
        XCTAssertTrue(homeserverTextField.waitForExistence(timeout: 10.0))
        
        homeserverTextField.clearAndTypeText(app.homeserver)
        
        let confirmButton = app.buttons[A11yIdentifiers.changeServerScreen.continue]
        XCTAssertTrue(confirmButton.waitForExistence(timeout: 10.0))
        confirmButton.tap()
        
        let continueButton = app.buttons[A11yIdentifiers.serverConfirmationScreen.continue]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 10.0))
        continueButton.tap()
        
        let usernameTextField = app.textFields[A11yIdentifiers.loginScreen.emailUsername]
        XCTAssertTrue(usernameTextField.waitForExistence(timeout: 10.0))
        
        usernameTextField.clearAndTypeText(app.username)
        
        let passwordTextField = app.secureTextFields[A11yIdentifiers.loginScreen.password]
        XCTAssertTrue(passwordTextField.waitForExistence(timeout: 10.0))
        
        passwordTextField.clearAndTypeText(app.password)
        
        let nextButton = app.buttons[A11yIdentifiers.loginScreen.continue]
        XCTAssertTrue(nextButton.waitForExistence(timeout: 10.0))
        XCTAssertTrue(nextButton.isEnabled)
        
        nextButton.tap()

        sleep(10)

        // Handle analytics prompt screen
        if app.staticTexts[A11yIdentifiers.analyticsPromptScreen.title].waitForExistence(timeout: 1.0) {
            // Wait for login and then handle save password sheet
            let savePasswordButton = app.buttons["Save Password"]
            if savePasswordButton.waitForExistence(timeout: 10.0) {
                savePasswordButton.tap()
            }
        
            let enableButton = app.buttons[A11yIdentifiers.analyticsPromptScreen.enable]
            XCTAssertTrue(enableButton.waitForExistence(timeout: 10.0))
            enableButton.tap()
        }

        // This might come in a different order, wait for both.
        let savePasswordButton = app.buttons["Save Password"]
        if savePasswordButton.waitForExistence(timeout: 10.0) {
            savePasswordButton.tap()
        }
        
        // Handle the notifications permission alert https://stackoverflow.com/a/58171074/730924
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let alertAllowButton = springboard.buttons.element(boundBy: 1)
        if alertAllowButton.waitForExistence(timeout: 10.0) {
            alertAllowButton.tap()
        }
        
        // Migration screen may be shown as an overlay.
        // if that pops up soon enough, we just let that happen and wait
        let message = app.staticTexts[A11yIdentifiers.migrationScreen.message]

        if message.waitForExistence(timeout: 10.0) {
            let doesNotExistPredicate = NSPredicate(format: "exists == 0")
            expectation(for: doesNotExistPredicate, evaluatedWith: message)
            waitForExpectations(timeout: 300.0)
        }

        // Welcome screen may be shown as an overlay.
        if app.buttons[A11yIdentifiers.welcomeScreen.letsGo].waitForExistence(timeout: 1.0) {
            let goButton = app.buttons[A11yIdentifiers.welcomeScreen.letsGo]
            XCTAssertTrue(goButton.waitForExistence(timeout: 1.0))
            goButton.tap()
        }

        // Wait for the home screen to become visible.
        let profileButton = app.buttons[A11yIdentifiers.homeScreen.userAvatar]
        // Timeouts are huge because we're waiting for the server.
        XCTAssertTrue(profileButton.waitForExistence(timeout: 300.0))
        
        // Open the first room in the list.
        let rooms = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", A11yIdentifiers.homeScreen.roomNamePrefix))
        rooms.firstMatch.tap()
        // Temporary sleep to get it working.
        sleep(20)
        // Go back to the home screen.
        app.navigationBars.firstMatch.buttons["All Chats"].tap()
        
        // `Failed to scroll to visible (by AX action) Button` https://stackoverflow.com/a/33534187/730924
        profileButton.forceTap()
        
        let menuLogoutButton = app.buttons["Sign out"]
        XCTAssertTrue(menuLogoutButton.waitForExistence(timeout: 10.0))
        menuLogoutButton.tap()
        
        let alertLogoutButton = app.buttons["Sign out"]
        XCTAssertTrue(alertLogoutButton.waitForExistence(timeout: 10.0))
        alertLogoutButton.tap()
        
        XCTAssertTrue(getStartedButton.waitForExistence(timeout: 10.0))
    }
}

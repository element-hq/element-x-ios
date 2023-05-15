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
    let expectedDuration = 100.0
    
    func testLoginFlow() throws {
        let parser = TestMeasurementParser()
        parser.capture(testCase: self) {
            self.measure(metrics: [XCTClockMetric()]) {
                self.runLoginLogoutFlow()
            }
        }
        
        guard let actualDuration = parser.valueForMetric(.clockMonotonicTime) else {
            XCTFail("Couldn't retrieve duration")
            return
        }
        
        XCTAssertLessThanOrEqual(actualDuration, expectedDuration)
    }
    
    private func runLoginLogoutFlow() {
        let app = Application.launch()
                
        let getStartedButton = app.buttons[A11yIdentifiers.onboardingScreen.signIn]
        
        XCTAssertTrue(getStartedButton.waitForExistence(timeout: 10.0))
        getStartedButton.tap()

        let editHomeserverButton = app.buttons[A11yIdentifiers.loginScreen.changeServer]
        XCTAssertTrue(editHomeserverButton.waitForExistence(timeout: 10.0))
        editHomeserverButton.tap()
        
        let homeserverTextField = app.textFields[A11yIdentifiers.changeServerScreen.server]
        XCTAssertTrue(homeserverTextField.waitForExistence(timeout: 10.0))
        
        homeserverTextField.clearAndTypeText(app.homeserver)
                
        let confirmButton = app.buttons[A11yIdentifiers.changeServerScreen.continue]
        XCTAssertTrue(confirmButton.waitForExistence(timeout: 10.0))
        confirmButton.tap()
        
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
        
        // Wait for login to finish
        let doesNotExistPredicate = NSPredicate(format: "exists == 0")
        expectation(for: doesNotExistPredicate, evaluatedWith: nextButton)
        waitForExpectations(timeout: expectedDuration)
        
        // Handle save password sheet
        let savePasswordButton = app.buttons["Save Password"]
        if savePasswordButton.waitForExistence(timeout: 10.0) {
            savePasswordButton.tap()
        }
        
        // Handle analytics prompt screen
        if app.staticTexts[A11yIdentifiers.analyticsPromptScreen.title].waitForExistence(timeout: 1.0) {
            let enableButton = app.buttons[A11yIdentifiers.analyticsPromptScreen.enable]
            XCTAssertTrue(enableButton.waitForExistence(timeout: 10.0))
            enableButton.tap()
        }
        
        // Handle the notifications permission alert https://stackoverflow.com/a/58171074/730924
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let alertAllowButton = springboard.buttons.element(boundBy: 1)
        if alertAllowButton.waitForExistence(timeout: 10.0) {
            alertAllowButton.tap()
        }
        
        let profileButton = app.buttons[A11yIdentifiers.homeScreen.userAvatar]
        XCTAssertTrue(profileButton.waitForExistence(timeout: 10.0))

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

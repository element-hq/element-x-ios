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
    let expectedDuration = 40.0
    
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
        
        let getStartedButton = app.buttons["Get started"]
        
        XCTAssertTrue(getStartedButton.waitForExistence(timeout: 5.0))
        getStartedButton.tap()
        
        let editHomeserverButton = app.buttons["editServerButton"]
        XCTAssertTrue(editHomeserverButton.waitForExistence(timeout: 5.0))
        editHomeserverButton.tap()
        
        let homeserverTextField = app.textFields["addressTextField"]
        XCTAssertTrue(homeserverTextField.waitForExistence(timeout: 5.0))
        
        homeserverTextField.clearAndTypeText(app.homeserver)
        
        let slidingSyncTextField = app.textFields["slidingSyncProxyAddressTextField"]
        XCTAssertTrue(slidingSyncTextField.waitForExistence(timeout: 5.0))
        
        slidingSyncTextField.clearAndTypeText(app.homeserver)
        
        let confirmButton = app.buttons["confirmButton"]
        XCTAssertTrue(confirmButton.exists)
        confirmButton.tap()
        
        let usernameTextField = app.textFields["usernameTextField"]
        XCTAssertTrue(usernameTextField.exists)
        
        usernameTextField.clearAndTypeText(app.username)
        
        let passwordTextField = app.secureTextFields["passwordTextField"]
        XCTAssertTrue(passwordTextField.exists)
        
        passwordTextField.clearAndTypeText(app.password)
        
        let nextButton = app.buttons["nextButton"]
        XCTAssertTrue(nextButton.exists)
        XCTAssertTrue(nextButton.isEnabled)
        
        nextButton.tap()
        
        let profileButton = app.buttons["userAvatarImage"]
        XCTAssertTrue(profileButton.waitForExistence(timeout: expectedDuration))
        profileButton.tap()
        
        let menuLogoutButton = app.buttons["Sign out"]
        XCTAssertTrue(menuLogoutButton.waitForExistence(timeout: 5.0))
        menuLogoutButton.tap()
        
        let alertLogoutButton = app.buttons["Sign out"]
        XCTAssertTrue(alertLogoutButton.waitForExistence(timeout: 5.0))
        alertLogoutButton.tap()
        
        XCTAssertTrue(getStartedButton.waitForExistence(timeout: 5.0))
    }
}

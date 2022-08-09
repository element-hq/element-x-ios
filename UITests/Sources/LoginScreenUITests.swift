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

import ElementX
import XCTest

@MainActor
class LoginScreenUITests: XCTestCase {
    var app: XCUIApplication!
    
    @MainActor
    override func setUp() async throws {
        app = nil
    }
    
    func testMatrixDotOrg() {
        // Given the initial login screen which defaults to matrix.org.
        app = Application.launch()
        app.goToScreenWithIdentifier(.login)
        
        let state = "matrix.org"
        validateLoginFormIsVisible(for: state)
        validateOIDCButtonIsHidden(for: state)
        validateNextButtonIsDisabled(for: state)
        validateUnsupportedServerTextIsHidden(for: state)
        
        // When typing in a username and password.
        app.textFields.element.tap()
        app.typeText("@test:matrix.org")
        
        app.secureTextFields.element.tap()
        app.typeText("12345678")
        
        // Then the form should be ready to submit.
        validateNextButtonIsEnabled(for: "matrix.org with credentials entered")
    }
    
    func testOIDC() {
        // Given the initial login screen.
        app = Application.launch()
        app.goToScreenWithIdentifier(.login)
        
        // When entering a username on a homeserver that only supports OIDC.
        app.textFields.element.tap()
        app.typeText("@test:company.com\n")
        
        // Then the screen should be configured for OIDC.
        let state = "an OIDC only server"
        validateOIDCButtonIsShown(for: state)
        validateLoginFormIsHidden(for: state)
        validateUnsupportedServerTextIsHidden(for: state)
    }
    
    func testUnsupported() {
        // Given the initial login screen.
        app = Application.launch()
        app.goToScreenWithIdentifier(.login)
        
        // When entering a username on a homeserver with an unsupported flow.
        app.textFields.element.tap()
        app.typeText("@test:server.net\n")
        
        // Then the screen should not allow login to continue.
        let state = "an unsupported server"
        validateUnsupportedServerTextIsShown(for: state)
        validateLoginFormIsHidden(for: state)
        validateOIDCButtonIsHidden(for: state)
    }
    
    /// Checks that the username and password text fields are shown along with the next button.
    func validateLoginFormIsVisible(for state: String) {
        let usernameTextField = app.textFields.element
        let passwordTextField = app.secureTextFields.element
        let nextButton = app.buttons["nextButton"]
        
        XCTAssertTrue(usernameTextField.exists, "Username input should be shown for \(state).")
        XCTAssertTrue(passwordTextField.exists, "Password input should be shown for \(state).")
        XCTAssertTrue(nextButton.exists, "The next button should be shown for \(state).")
        XCTAssertEqual(nextButton.label, ElementL10n.loginSignupSubmit)
    }
    
    /// Checks that the username and password text fields are hidden along with the next button.
    func validateLoginFormIsHidden(for state: String) {
        let usernameTextField = app.textFields.element
        let passwordTextField = app.secureTextFields.element
        let nextButton = app.buttons["nextButton"]
        
        XCTAssertFalse(usernameTextField.exists, "Username input should not be shown for \(state).")
        XCTAssertFalse(passwordTextField.exists, "Password input should not be shown for \(state).")
        XCTAssertFalse(nextButton.exists, "The next button should not be shown for \(state).")
    }
    
    /// Checks that the next button is shown but is disabled.
    func validateNextButtonIsDisabled(for state: String) {
        let nextButton = app.buttons["nextButton"]
        XCTAssertTrue(nextButton.exists, "The next button should be shown.")
        XCTAssertFalse(nextButton.isEnabled, "The next button should be disabled for \(state).")
        XCTAssertEqual(nextButton.label, ElementL10n.loginSignupSubmit)
    }
    
    /// Checks that the next button is shown and is enabled.
    func validateNextButtonIsEnabled(for state: String) {
        let nextButton = app.buttons["nextButton"]
        XCTAssertTrue(nextButton.exists, "The next button should be shown.")
        XCTAssertTrue(nextButton.isEnabled, "The next button should be enabled for \(state).")
        XCTAssertEqual(nextButton.label, ElementL10n.loginSignupSubmit)
    }
    
    /// Checks that the OIDC button is shown on the screen.
    func validateOIDCButtonIsShown(for state: String) {
        let oidcButton = app.buttons["oidcButton"]
        XCTAssertTrue(oidcButton.waitForExistence(timeout: 1), "The OIDC button should be shown for \(state).")
        XCTAssertEqual(oidcButton.label, ElementL10n.loginContinue)
    }
    
    /// Checks that the OIDC button is not shown on the screen.
    func validateOIDCButtonIsHidden(for state: String) {
        let oidcButton = app.buttons["oidcButton"]
        XCTAssertFalse(oidcButton.exists, "The OIDC button should be hidden for \(state).")
    }
    
    /// Checks that the unsupported homeserver text is shown on the screen.
    func validateUnsupportedServerTextIsShown(for state: String) {
        let unsupportedText = app.staticTexts["unsupportedServerText"]
        XCTAssertTrue(unsupportedText.waitForExistence(timeout: 1), "The unsupported homeserver text should be shown for \(state).")
        XCTAssertEqual(unsupportedText.label, ElementL10n.autodiscoverWellKnownError)
    }
    
    /// Checks that the unsupported homeserver text is not shown on the screen.
    func validateUnsupportedServerTextIsHidden(for state: String) {
        let unsupportedText = app.staticTexts["unsupportedServerText"]
        XCTAssertFalse(unsupportedText.exists, "The unsupported homeserver text should be hidden for \(state).")
    }
}

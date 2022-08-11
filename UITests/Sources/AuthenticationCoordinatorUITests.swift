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

@testable import ElementX

@MainActor
class AuthenticationCoordinatorUITests: XCTestCase {
    func testLoginWithPassword() {
        // Given the authentication flow.
        let app = Application.launch()
        app.goToScreenWithIdentifier(.authenticationFlow)
        
        // Splash Screen: Tap get started button
        app.buttons["getStartedButton"].tap()
        
        // Login Screen: Enter valid credentials
        app.textFields["usernameTextField"].tap()
        app.typeText("alice\n")
        app.secureTextFields["passwordTextField"].tap()
        app.typeText("12345678")
        
        // Login Screen: Tap next
        app.buttons["nextButton"].tap()
        
        // Then login should succeed.
        XCTAssertFalse(app.alerts.element.exists, "No alert should be shown when logging in with valid credentials.")
    }
    
    func testLoginWithIncorrectPassword() {
        // Given the authentication flow.
        let app = Application.launch()
        app.goToScreenWithIdentifier(.authenticationFlow)
        
        // Splash Screen: Tap get started button
        app.buttons["getStartedButton"].tap()
        
        // Login Screen: Enter invalid credentials
        app.textFields["usernameTextField"].tap()
        app.typeText("alice\n")
        app.typeText("87654321\n")
        
        // Then login should fail.
        XCTAssertTrue(app.alerts.element.exists, "An error alert should be shown when attempting login with invalid credentials.")
    }
    
    func testSelectingOIDCServer() {
        // Given the authentication flow.
        let app = Application.launch()
        app.goToScreenWithIdentifier(.authenticationFlow)
        
        // Splash Screen: Tap get started button
        app.buttons["getStartedButton"].tap()
        
        // Login Screen: Tap edit server button.
        XCTAssertFalse(app.buttons["oidcButton"].exists, "The OIDC button shouldn't be shown before entering a supported homeserver.")
        app.buttons["editServerButton"].tap()
        
        // Server Selection: Clear the default and enter OIDC server.
        app.textFields["addressTextField"].tap()
        app.textFields["addressTextField"].buttons.element.tap()
        app.typeText("company.com")
        
        // Dismiss server screen.
        app.buttons["confirmButton"].tap()
        
        // Then the login form should be updated for OIDC.
        XCTAssertTrue(app.buttons["oidcButton"].waitForExistence(timeout: 1), "The OIDC button should be shown after selecting a homeserver with OIDC.")
    }
}

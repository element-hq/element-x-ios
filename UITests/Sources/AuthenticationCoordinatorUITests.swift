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
    func testLoginWithPassword() async throws {
        // Given the authentication flow.
        let app = Application.launch(.authenticationFlow)
        
        // Splash Screen: Tap get started button
        app.buttons[A11yIdentifiers.onboardingScreen.signIn].tap()
        
        // Server Confirmation: Tap continue button
        app.buttons[A11yIdentifiers.serverConfirmationScreen.continue].tap()
        
        // Login Screen: Enter valid credentials
        app.textFields[A11yIdentifiers.loginScreen.emailUsername].clearAndTypeText("alice\n")
        app.secureTextFields[A11yIdentifiers.loginScreen.password].clearAndTypeText("12345678")

        try await app.assertScreenshot(.authenticationFlow)
        
        // Login Screen: Tap next
        app.buttons[A11yIdentifiers.loginScreen.continue].tap()

        XCTAssertTrue(app.staticTexts[A11yIdentifiers.analyticsPromptScreen.title].waitForExistence(timeout: 1.0), "The analytics prompt screen should be seen after login")
    }
    
    func testLoginWithIncorrectPassword() async throws {
        // Given the authentication flow.
        let app = Application.launch(.authenticationFlow)
        
        // Splash Screen: Tap get started button
        app.buttons[A11yIdentifiers.onboardingScreen.signIn].tap()
        
        // Server Confirmation: Tap continue button
        app.buttons[A11yIdentifiers.serverConfirmationScreen.continue].tap()
        
        // Login Screen: Enter invalid credentials
        app.textFields[A11yIdentifiers.loginScreen.emailUsername].clearAndTypeText("alice")
        app.secureTextFields[A11yIdentifiers.loginScreen.password].clearAndTypeText("87654321")

        // Login Screen: Tap next
        let nextButton = app.buttons[A11yIdentifiers.loginScreen.continue]
        XCTAssertTrue(nextButton.waitForExistence(timeout: 2.0))
        XCTAssertTrue(nextButton.isEnabled)
        nextButton.tap()
        
        // Then login should fail.
        XCTAssertTrue(app.alerts.element.waitForExistence(timeout: 2.0), "An error alert should be shown when attempting login with invalid credentials.")
    }
    
    func testSelectingOIDCServer() {
        // Given the authentication flow.
        let app = Application.launch(.authenticationFlow)
        
        // Splash Screen: Tap get started button
        app.buttons[A11yIdentifiers.onboardingScreen.signIn].tap()
        
        // Server Confirmation: Tap change server button
        app.buttons[A11yIdentifiers.serverConfirmationScreen.changeServer].tap()
        
        // Server Selection: Clear the default, enter OIDC server and continue.
        app.textFields[A11yIdentifiers.changeServerScreen.server].clearAndTypeText("company.com\n")
        
        // Server Confirmation: Tap continue button
        app.buttons[A11yIdentifiers.serverConfirmationScreen.continue].tap()
        
        // Then the login form shouldn't be shown as OIDC will be used instead.
        XCTAssertFalse(app.buttons[A11yIdentifiers.loginScreen.continue].waitForExistence(timeout: 1), "The login screen should not be shown after selecting a homeserver with OIDC.")
    }
}

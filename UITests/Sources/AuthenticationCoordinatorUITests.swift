//
//  AuthenticationCoordinatorUITests.swift
//  UITests
//
//  Created by Doug on 30/06/2022.
//  Copyright © 2022 Element. All rights reserved.
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

        app.assertScreenshot(.authenticationFlow)
        
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
        app.typeText("87654321")

        // Login Screen: Tap next
        app.buttons["nextButton"].tap()
        
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

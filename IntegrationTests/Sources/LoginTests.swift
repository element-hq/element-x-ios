//
//  LoginTest.swift
//  IntegrationTests
//
//  Created by Stefan Ceriu on 25/07/2022.
//  Copyright © 2022 Element. All rights reserved.
//

import XCTest

class LoginTests: XCTestCase {
    func testLoginFlow() throws {
        let parser = XCTestMeasurementParser()
        parser.capture(testCase: self) {
            self.measure(metrics: [XCTClockMetric()]) {
                self.runLoginLogoutFlow()
            }
        }
        
        guard let actualDuration = parser.valueForMetric(.clockMonotonicTime) else {
            XCTFail("Couldn't retrieve duration")
            return
        }
        
        let expectedDuration = 30.0
        
        XCTAssert(actualDuration <= expectedDuration, "Login-logout flow duration: \(actualDuration) greater than expected: \(expectedDuration)")
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
        
        let confirmButton = app.buttons["confirmButton"]
        XCTAssertTrue(confirmButton.waitForExistence(timeout: 5.0))
        confirmButton.tap()
        
        let usernameTextField = app.textFields["usernameTextField"]
        XCTAssertTrue(usernameTextField.waitForExistence(timeout: 5.0))
        
        usernameTextField.tap()
        usernameTextField.typeText(app.username)
        
        let passwordTextField = app.secureTextFields["passwordTextField"]
        XCTAssertTrue(passwordTextField.waitForExistence(timeout: 5.0))
        
        passwordTextField.tap()
        passwordTextField.typeText(app.password)
        
        let nextButton = app.buttons["nextButton"]
        XCTAssertTrue(nextButton.waitForExistence(timeout: 5.0))
        XCTAssertTrue(nextButton.isEnabled)
        
        nextButton.tap()
        
        let profileButton = app.buttons["userDisplayNameView"]
        XCTAssertTrue(profileButton.waitForExistence(timeout: 60.0))
        profileButton.tap()
        
        let logoutButton = app.buttons["logoutButton"]
        XCTAssertTrue(logoutButton.waitForExistence(timeout: 5.0))
        logoutButton.tap()
        
        let logoutSheetButton = app.buttons["Sign out"].firstMatch
        XCTAssertTrue(logoutSheetButton.waitForExistence(timeout: 5.0))
        logoutSheetButton.tap()
    }
}

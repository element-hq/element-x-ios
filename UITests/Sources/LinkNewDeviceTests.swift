//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import XCTest

@MainActor
class LinkNewDeviceTests: XCTestCase {
    enum Step {
        static let selectDevice = 1
        static let linkMobileDevice = 2
        static let linkDesktopComputer = 3
        static let appLockPIN = 4
        static let logoutAlert = 5
        static let forcedLogout = 6
        static let dismissed = 99
    }
    
    func testFlow() async throws {
        // Root screen
        let app = Application.launch(.linkNewDevice)
        try await app.assertScreenshot(step: Step.selectDevice)
        
        // Link showing a QR code
        let mobileDeviceButton = app.buttons[A11yIdentifiers.linkNewDeviceScreen.mobileDevice]
        mobileDeviceButton.tap()
        try await app.assertScreenshot(step: Step.linkMobileDevice)
        
        // Pop back to the root screen
        let backButton = app.buttons["Link new device"]
        backButton.tap()
        try await app.assertScreenshot(step: Step.selectDevice)
        
        // Link scanning a QR code
        let desktopComputerButton = app.buttons[A11yIdentifiers.linkNewDeviceScreen.desktopComputer]
        desktopComputerButton.tap()
        try await app.assertScreenshot(step: Step.linkDesktopComputer)
        
        // Pop back to the root screen
        backButton.tap()
        try await app.assertScreenshot(step: Step.selectDevice)
        
        // Dismiss the flow
        let cancelButton = app.buttons[A11yIdentifiers.linkNewDeviceScreen.cancel]
        cancelButton.tap()
        try await app.assertScreenshot(step: Step.dismissed)
    }
    
    func testAppLockPINVerification() async throws {
        // Root screen
        let app = Application.launch(.linkNewDeviceWithAppLockPIN)
        try await app.assertScreenshot(step: Step.selectDevice)
        
        // Linking requires verifying the device owner with the App Lock PIN.
        let mobileDeviceButton = app.buttons[A11yIdentifiers.linkNewDeviceScreen.mobileDevice]
        mobileDeviceButton.tap()
        try await app.assertScreenshot(step: Step.appLockPIN)
        
        // Cancelling verification returns to the root screen.
        app.buttons[A11yIdentifiers.appLockScreen.cancel].tap()
        try await app.assertScreenshot(step: Step.selectDevice)
        
        // Entering the correct PIN continues to generate the QR code.
        mobileDeviceButton.tap()
        try await app.assertScreenshot(step: Step.appLockPIN)
        enterPIN(app)
        try await app.assertScreenshot(step: Step.linkMobileDevice)
    }
    
    func testForceLogout() async throws {
        // Root screen
        let app = Application.launch(.linkNewDeviceWithAppLockPIN)
        
        // Linking requires verifying the device owner with the App Lock PIN.
        app.buttons[A11yIdentifiers.linkNewDeviceScreen.mobileDevice].tap()
        try await app.assertScreenshot(step: Step.appLockPIN)
        
        // Entering the wrong PIN three times signs the user out.
        enterWrongPIN(app)
        enterWrongPIN(app)
        enterWrongPIN(app)
        try await app.assertScreenshot(step: Step.logoutAlert)
        app.alerts.element.buttons[A11yIdentifiers.alertInfo.primaryButton].firstMatch.tap()
        try await app.assertScreenshot(step: Step.forcedLogout)
    }
    
    // MARK: - Helpers
    
    private func enterPIN(_ app: XCUIApplication) {
        app.buttons[A11yIdentifiers.appLockScreen.numpad(2)].tap()
        app.buttons[A11yIdentifiers.appLockScreen.numpad(0)].tap()
        app.buttons[A11yIdentifiers.appLockScreen.numpad(2)].tap()
        app.buttons[A11yIdentifiers.appLockScreen.numpad(3)].tap()
    }
    
    private func enterWrongPIN(_ app: XCUIApplication) {
        for _ in 0..<4 {
            app.buttons[A11yIdentifiers.appLockScreen.numpad(0)].tap()
        }
    }
}

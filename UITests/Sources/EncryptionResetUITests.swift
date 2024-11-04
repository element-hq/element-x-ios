//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import XCTest

@MainActor
class EncryptionResetUITests: XCTestCase {
    var app: XCUIApplication!
    
    @MainActor enum Step {
        static let resetScreen = 0
        static let passwordScreen = 1
        static let resetingEncryption = 2
    }
    
    func testPasswordFlow() async throws {
        app = Application.launch(.encryptionReset)
        
        // Starting with the root screen.
        try await app.assertScreenshot(.encryptionReset, step: Step.resetScreen)
        
        // Confirm the intent to reset.
        app.buttons[A11yIdentifiers.encryptionResetScreen.continueReset].tap()
        app.buttons[A11yIdentifiers.alertInfo.primaryButton].tap()
        try await app.assertScreenshot(.encryptionReset, step: Step.passwordScreen)
        
        // Enter the password and submit.
        let passwordField = app.secureTextFields[A11yIdentifiers.encryptionResetPasswordScreen.passwordField]
        passwordField.clearAndTypeText("supersecurepassword", app: app)
        app.buttons[A11yIdentifiers.encryptionResetPasswordScreen.submit].tap()
        try await app.assertScreenshot(.encryptionReset, step: Step.resetingEncryption)
    }
}

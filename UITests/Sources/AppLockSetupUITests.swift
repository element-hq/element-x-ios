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

@MainActor
class AppLockSetupUITests: XCTestCase {
    var app: XCUIApplication!
    
    @MainActor enum Step {
        static let createPIN = 0
        static let confirmPIN = 1
        static let setupBiometrics = 2
        static let settings = 3
        
        /// iPad shows the settings screen behind the modal, iPhone doesn't.
        static let changePIN = isPhone ? createPIN : 4
        /// iPad shows the settings screen behind the modal, iPhone doesn't.
        static let confirmChangePIN = isPhone ? confirmPIN : 5
        
        /// Not part of the flow, only to verify the stack is cleared.
        static let clearedStack = 99
        
        static var isPhone: Bool { UIDevice.current.userInterfaceIdiom == .phone }
    }
    
    func testCreateFlow() async throws {
        app = Application.launch(.appLockSetupFlow)
        
        // Create PIN screen.
        try await app.assertScreenshot(.appLockSetupFlow, step: Step.createPIN)
        
        enterPIN()
        
        // Confirm PIN screen.
        try await app.assertScreenshot(.appLockSetupFlow, step: Step.confirmPIN)
        
        enterPIN()
        
        // Setup biometrics screen.
        try await app.assertScreenshot(.appLockSetupFlow, step: Step.setupBiometrics)
        
        app.buttons[A11yIdentifiers.appLockSetupBiometricsScreen.allow].tap()
        
        // Settings screen.
        try await app.assertScreenshot(.appLockSetupFlow, step: Step.settings)
        
        app.buttons[A11yIdentifiers.appLockSetupSettingsScreen.changePIN].tap()
        
        // Change PIN (create).
        try await app.assertScreenshot(.appLockSetupFlow, step: Step.changePIN)
        
        enterDifferentPIN()
        
        // Change PIN (confirm).
        try await app.assertScreenshot(.appLockSetupFlow, step: Step.confirmChangePIN)
        
        enterDifferentPIN()
        
        // Settings screen.
        try await app.assertScreenshot(.appLockSetupFlow, step: Step.settings)
        
        app.buttons[A11yIdentifiers.appLockSetupSettingsScreen.removePIN].tap()
        app.alerts.element.buttons[A11yIdentifiers.alertInfo.primaryButton].tap()
        
        // Pop the stack returning to whatever was last presented.
        try await app.assertScreenshot(.appLockSetupFlow, step: Step.clearedStack)
    }
    
    func testMandatoryCreateFlow() async throws {
        app = Application.launch(.appLockSetupFlowMandatory)
        
        // Create PIN screen (non-modal and no cancellation button).
        try await app.assertScreenshot(.appLockSetupFlowMandatory, step: Step.createPIN)
        
        enterPIN()
        
        // Confirm PIN screen (non-modal and no cancellation button).
        try await app.assertScreenshot(.appLockSetupFlowMandatory, step: Step.confirmPIN)
        
        enterPIN()
        
        // Setup biometrics screen (non-modal).
        try await app.assertScreenshot(.appLockSetupFlowMandatory, step: Step.setupBiometrics)
        
        let allowButton = app.buttons[A11yIdentifiers.appLockSetupBiometricsScreen.allow]
        XCTAssertTrue(allowButton.exists, "The biometrics screen should be shown.")
        allowButton.tap()
        
        // The stack should remain on biometrics for the presenting flow to take over navigation.
        try await app.assertScreenshot(.appLockSetupFlowMandatory, step: Step.setupBiometrics)
    }
    
    func testUnlockFlow() async throws {
        app = Application.launch(.appLockSetupFlowUnlock)
        
        // Create PIN screen.
        try await app.assertScreenshot(.appLockSetupFlowUnlock)
        
        enterPIN()
        
        // Settings screen.
        try await app.assertScreenshot(.appLockSetupFlow, step: Step.settings)
        
        app.buttons[A11yIdentifiers.appLockSetupSettingsScreen.removePIN].tap()
        app.alerts.element.buttons[A11yIdentifiers.alertInfo.primaryButton].tap()
        
        // Pop the stack returning to whatever was last presented.
        try await app.assertScreenshot(.appLockSetupFlow, step: Step.clearedStack)
    }
    
    func testCancel() async throws {
        app = Application.launch(.appLockSetupFlowUnlock)
        
        // Create PIN screen.
        try await app.assertScreenshot(.appLockSetupFlowUnlock)
        
        app.buttons[A11yIdentifiers.appLockSetupPINScreen.cancel].tap()
        
        // Return to whatever was last presented.
        try await app.assertScreenshot(.appLockSetupFlow, step: Step.clearedStack)
    }
    
    // MARK: - Helpers
    
    private func enterPIN() {
        let textField = app.secureTextFields[A11yIdentifiers.appLockSetupPINScreen.textField]
        XCTAssert(textField.waitForExistence(timeout: 10))
        
        textField.clearAndTypeText("2023")
    }
    
    private func enterDifferentPIN() {
        let textField = app.secureTextFields[A11yIdentifiers.appLockSetupPINScreen.textField]
        XCTAssert(textField.waitForExistence(timeout: 10))
        
        textField.clearAndTypeText("2233")
    }
}

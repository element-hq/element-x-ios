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
class AppLockSetupUITests: XCTestCase {
    var app: XCUIApplication!
    
    enum Step {
        static let createPIN = 0
        static let confirmPIN = 1
        static let setupBiometrics = 2
        static let settings = 3
        
        /// Not part of the flow, only to verify the stack is cleared.
        static let clearedStack = 99
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
        try await app.assertScreenshot(.appLockSetupFlow, step: Step.createPIN)
        
        enterDifferentPIN()
        
        // Change PIN (confirm).
        try await app.assertScreenshot(.appLockSetupFlow, step: Step.confirmPIN)
        
        enterDifferentPIN()
        
        // Settings screen.
        try await app.assertScreenshot(.appLockSetupFlow, step: Step.settings)
        
        app.buttons[A11yIdentifiers.appLockSetupSettingsScreen.removePIN].tap()
        app.alerts.element.buttons[A11yIdentifiers.alertInfo.primaryButton].tap()
        
        // Pop the stack returning to whatever was last presented.
        try await app.assertScreenshot(.appLockSetupFlow, step: Step.clearedStack)
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
        app.keys["2"].tap()
        app.keys["0"].tap()
        app.keys["2"].tap()
        app.keys["3"].tap()
    }
    
    private func enterDifferentPIN() {
        app.keys["2"].tap()
        app.keys["2"].tap()
        app.keys["3"].tap()
        app.keys["3"].tap()
    }
}

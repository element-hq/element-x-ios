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
class AppLockUITests: XCTestCase {
    var app: XCUIApplication!
    
    enum Step {
        static let placeholder = 0
        static let lockScreen = 1
        static let failedUnlock = 2
        static let logoutAlert = 3
        static let forcedLogout = 4
        static let unlocked = 99
    }
    
    func testFlowEnabled() async throws {
        // Given an app with screen lock enabled.
        let client = try UITestsSignalling.Client(mode: .tests)
        app = Application.launch(.appLockFlow)
        await client.waitForApp()
        
        // Blank form representing an unlocked app.
        try await app.assertScreenshot(.appLockFlow, step: Step.unlocked)
        
        // When backgrounding the app.
        try client.send(.notification(name: UIApplication.didEnterBackgroundNotification))
        
        // Then the placeholder screen should obscure the content.
        try await app.assertScreenshot(.appLockFlow, step: Step.placeholder)
        
        // When foregrounding the app.
        try client.send(.notification(name: UIApplication.didBecomeActiveNotification))
        
        // Then the Lock Screen should be shown to enter a PIN.
        try await app.assertScreenshot(.appLockFlow, step: Step.lockScreen)
        
        // When entering a PIN
        enterPIN()
        
        // Then the app should be unlocked again.
        try await app.assertScreenshot(.appLockFlow, step: Step.unlocked)
    }
    
    func testFlowDisabled() async throws {
        // Given an app with screen lock enabled.
        let client = try UITestsSignalling.Client(mode: .tests)
        app = Application.launch(.appLockFlowDisabled)
        await client.waitForApp()
        
        // Blank form representing an unlocked app.
        try await app.assertScreenshot(.appLockFlow, step: Step.unlocked)
        
        // When backgrounding the app.
        try client.send(.notification(name: UIApplication.didEnterBackgroundNotification))
        
        // Then the app should remain unlocked.
        try await app.assertScreenshot(.appLockFlow, step: Step.unlocked)
        
        // When foregrounding the app.
        try client.send(.notification(name: UIApplication.didBecomeActiveNotification))
        
        // Then the app should still remain unlocked.
        try await app.assertScreenshot(.appLockFlow, step: Step.unlocked)
    }
    
    func testWrongPIN() async throws {
        // Given an app with screen lock enabled that is ready to unlock.
        let client = try UITestsSignalling.Client(mode: .tests)
        app = Application.launch(.appLockFlow)
        await client.waitForApp()
        
        try await app.assertScreenshot(.appLockFlow, step: Step.unlocked)
        try client.send(.notification(name: UIApplication.didEnterBackgroundNotification))
        try await Task.sleep(for: .milliseconds(500)) // Don't overwrite the previous signal immediately.
        try client.send(.notification(name: UIApplication.didBecomeActiveNotification))
        try await app.assertScreenshot(.appLockFlow, step: Step.lockScreen)
        
        // When entering an incorrect PIN
        enterWrongPIN()
        
        // Then the app should remain locked with a warning.
        try await app.assertScreenshot(.appLockFlow, step: Step.failedUnlock)
        
        // When entering it incorrectly twice more.
        enterWrongPIN()
        enterWrongPIN()
        
        // Then then the app should sign the user out.
        try await app.assertScreenshot(.appLockFlow, step: Step.logoutAlert)
        app.alerts.element.buttons[A11yIdentifiers.alertInfo.primaryButton].tap()
        try await app.assertScreenshot(.appLockFlow, step: Step.forcedLogout)
    }
    
    func testResignActive() async throws {
        // Given an app with screen lock enabled.
        let client = try UITestsSignalling.Client(mode: .tests)
        app = Application.launch(.appLockFlow)
        await client.waitForApp()
        
        // Blank form representing an unlocked app.
        try await app.assertScreenshot(.appLockFlow, step: Step.unlocked)
        
        // When the app resigns active but doesn't enter the background.
        try client.send(.notification(name: UIApplication.willResignActiveNotification))
        
        // Then the placeholder screen should obscure the content.
        try await app.assertScreenshot(.appLockFlow, step: Step.placeholder)
        
        // When the app becomes active again.
        try client.send(.notification(name: UIApplication.didBecomeActiveNotification))
        
        // Then the app should not have become unlock.
        try await app.assertScreenshot(.appLockFlow, step: Step.unlocked)
    }
    
    // MARK: - Helpers
    
    func enterPIN() {
        app.buttons[A11yIdentifiers.appLockScreen.numpad(2)].tap()
        app.buttons[A11yIdentifiers.appLockScreen.numpad(0)].tap()
        app.buttons[A11yIdentifiers.appLockScreen.numpad(2)].tap()
        app.buttons[A11yIdentifiers.appLockScreen.numpad(3)].tap()
    }
    
    func enterWrongPIN() {
        app.buttons[A11yIdentifiers.appLockScreen.numpad(0)].tap()
        app.buttons[A11yIdentifiers.appLockScreen.numpad(0)].tap()
        app.buttons[A11yIdentifiers.appLockScreen.numpad(0)].tap()
        app.buttons[A11yIdentifiers.appLockScreen.numpad(0)].tap()
    }
}

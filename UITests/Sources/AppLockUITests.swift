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
class AppLockUITests: XCTestCase {
    var app: XCUIApplication!
    
    enum Step {
        static let placeholder = 0
        static let lockScreen = 1
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
        try client.send(.notification(name: UIApplication.willEnterForegroundNotification))
        
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
        try client.send(.notification(name: UIApplication.willEnterForegroundNotification))
        
        // Then the app should still remain unlocked.
        try await app.assertScreenshot(.appLockFlow, step: Step.unlocked)
    }
    
    // MARK: - Helpers
    
    func enterPIN() {
        app.buttons[A11yIdentifiers.appLockScreen.numpad(2)].tap()
        app.buttons[A11yIdentifiers.appLockScreen.numpad(0)].tap()
        app.buttons[A11yIdentifiers.appLockScreen.numpad(2)].tap()
        app.buttons[A11yIdentifiers.appLockScreen.numpad(3)].tap()
    }
}

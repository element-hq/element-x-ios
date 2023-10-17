//
// Copyright 2023 New Vector Ltd
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
class AppLockServiceTests: XCTestCase {
    var appSettings: AppSettings!
    var service: AppLockService!
    
    override func setUp() {
        AppSettings.reset()
        appSettings = AppSettings()
        appSettings.appLockFlowEnabled = true
        
        let keychainController = KeychainController(service: .tests, accessGroup: InfoPlistReader.main.keychainAccessGroupIdentifier)
        
        service = AppLockService(keychainController: keychainController, appSettings: appSettings)
        service.disable()
    }
    
    override func tearDown() {
        AppSettings.reset()
    }
    
    func testValidPINCode() {
        // Given a service that hasn't been enabled.
        XCTAssertFalse(service.isEnabled, "The service shouldn't be enabled to begin with.")
        
        // When setting a PIN code.
        let pinCode = "2023" // Highly secure PIN that is rotated every 12 months.
        guard case .success = service.setupPINCode(pinCode) else {
            XCTFail("The PIN should be valid.")
            return
        }
        
        // Then service should be enabled and only the provided PIN should work to unlock the app.
        XCTAssertTrue(service.isEnabled, "The service should become enabled when setting a PIN.")
        XCTAssertTrue(service.unlock(with: pinCode), "The provided PIN code should work.")
        XCTAssertFalse(service.unlock(with: "2024"), "No other PIN code should work.")
        XCTAssertFalse(service.unlock(with: "1234"), "No other PIN code should work.")
        XCTAssertFalse(service.unlock(with: "9999"), "No other PIN code should work.")
    }
    
    func testInvalidPINCode() {
        // Given a service that hasn't been enabled.
        XCTAssertFalse(service.isEnabled, "The service shouldn't be enabled to begin with.")
        
        // When setting a PIN code that is in the block list.
        let pinCode = appSettings.appLockPINCodeBlockList[0]
        let result = service.setupPINCode(pinCode)
        
        // Then the setup should fail and the service be left as disabled.
        guard case let .failure(error) = result else {
            XCTFail("The call should have failed.")
            return
        }
        XCTAssertEqual(error, .weakPIN, "The PIN should be rejected as weak.")
        XCTAssertFalse(service.isEnabled, "The service should remain disabled.")
    }
    
    func testChangePINCode() {
        // Given a service that is already enabled with a PIN.
        let pinCode = "2023"
        let newPINCode = "2024"
        guard case .success = service.setupPINCode(pinCode) else {
            XCTFail("The PIN should be valid.")
            return
        }
        XCTAssertTrue(service.isEnabled, "The service should be enabled.")
        XCTAssertTrue(service.unlock(with: pinCode), "The initial PIN should work.")
        XCTAssertFalse(service.unlock(with: newPINCode), "The PIN we're about to set should not work.")
        
        // When updating the PIN code.
        guard case .success = service.setupPINCode(newPINCode) else {
            XCTFail("The PIN should be valid.")
            return
        }
        
        // Then the old code should not be accepted.
        XCTAssertTrue(service.isEnabled, "The service should remain enabled.")
        XCTAssertTrue(service.unlock(with: newPINCode), "The new PIN should work.")
        XCTAssertFalse(service.unlock(with: pinCode), "The original PIN should be rejected.")
    }
    
    func testInvalidChangePINCode() {
        // Given a service that is already enabled with a PIN.
        let pinCode = "2023"
        let invalidPIN = appSettings.appLockPINCodeBlockList[0]
        guard case .success = service.setupPINCode(pinCode) else {
            XCTFail("The PIN should be valid.")
            return
        }
        XCTAssertTrue(service.isEnabled, "The service should be enabled.")
        XCTAssertTrue(service.unlock(with: pinCode), "The initial PIN should work.")
        XCTAssertFalse(service.unlock(with: invalidPIN), "The PIN we're about to set should not work.")
        
        // When updating the PIN code that is in the block list.
        let result = service.setupPINCode(invalidPIN)
        
        // Then it should fail and nothing should change.
        guard case let .failure(error) = result else {
            XCTFail("The call should have failed.")
            return
        }
        XCTAssertEqual(error, .weakPIN, "The PIN should be rejected as weak.")
        XCTAssertTrue(service.isEnabled, "The service should remain enabled.")
        XCTAssertFalse(service.unlock(with: invalidPIN), "The rejected PIN shouldn't work.")
        XCTAssertTrue(service.unlock(with: pinCode), "The original PIN should continue to work.")
    }
    
    func testDisablePINCode() {
        // Given a service that is already enabled with a PIN.
        let pinCode = "2023"
        guard case .success = service.setupPINCode(pinCode) else {
            XCTFail("The PIN should be valid.")
            return
        }
        XCTAssertTrue(service.isEnabled, "The service should be enabled.")
        XCTAssertTrue(service.unlock(with: pinCode), "The initial PIN should work.")
        
        // When disabling the PIN code.
        service.disable()
        
        // Then the PIN code should be removed.
        XCTAssertFalse(service.isEnabled, "The service should no longer be enabled.")
        XCTAssertFalse(service.unlock(with: pinCode), "The initial PIN shouldn't work any more.")
    }
}

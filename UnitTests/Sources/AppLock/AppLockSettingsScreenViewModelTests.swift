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
class AppLockSettingsScreenViewModelTests: XCTestCase {
    var appLockService: AppLockServiceProtocol!
    var keychainController: KeychainControllerMock!
    var viewModel: AppLockSettingsScreenViewModelProtocol!
    
    var context: AppLockSettingsScreenViewModelType.Context {
        viewModel.context
    }
    
    override func setUpWithError() throws {
        AppSettings.reset()
        let appSettings = AppSettings()
        appSettings.appLockFlowEnabled = true
        
        keychainController = KeychainControllerMock()
        appLockService = AppLockService(keychainController: keychainController, appSettings: appSettings)
        
        viewModel = AppLockSettingsScreenViewModel(appLockService: AppLockServiceMock.mock())
    }
    
    override func tearDown() {
        AppSettings.reset()
    }

    func testDisablingShowsAlert() {
        // Given a fresh screen with the PIN code enabled.
        let pinCode = "2023"
        keychainController.pinCodeReturnValue = pinCode
        keychainController.containsPINCodeReturnValue = true
        
        XCTAssertNil(context.alertInfo)
        XCTAssertTrue(appLockService.isEnabled)
        
        // When disabling the PIN code lock.
        context.send(viewAction: .disable)
        
        // Then an alert should be shown before disabling it.
        XCTAssertNotNil(context.alertInfo)
        XCTAssertTrue(appLockService.isEnabled)
    }
}

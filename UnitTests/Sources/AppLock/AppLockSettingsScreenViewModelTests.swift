//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import XCTest

@testable import ElementX

@MainActor
class AppLockSetupSettingsScreenViewModelTests: XCTestCase {
    var appLockService: AppLockServiceProtocol!
    var keychainController: KeychainControllerMock!
    var viewModel: AppLockSetupSettingsScreenViewModelProtocol!
    
    var context: AppLockSetupSettingsScreenViewModelType.Context {
        viewModel.context
    }
    
    override func setUpWithError() throws {
        keychainController = KeychainControllerMock()
        appLockService = AppLockService(keychainController: keychainController, appSettings: AppSettings())
        
        viewModel = AppLockSetupSettingsScreenViewModel(appLockService: AppLockServiceMock.mock())
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

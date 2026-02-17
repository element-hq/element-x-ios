//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Testing

@MainActor
@Suite
struct AppLockSetupSettingsScreenViewModelTests {
    @MainActor
    private struct TestSetup {
        var appLockService: AppLockServiceProtocol
        var keychainController: KeychainControllerMock
        var viewModel: AppLockSetupSettingsScreenViewModelProtocol
        
        var context: AppLockSetupSettingsScreenViewModelType.Context {
            viewModel.context
        }
        
        init() {
            keychainController = KeychainControllerMock()
            appLockService = AppLockService(keychainController: keychainController, appSettings: AppSettings())
            viewModel = AppLockSetupSettingsScreenViewModel(appLockService: AppLockServiceMock.mock())
        }
    }

    @Test
    func disablingShowsAlert() {
        var testSetup = TestSetup()
        
        // Given a fresh screen with the PIN code enabled.
        let pinCode = "2023"
        testSetup.keychainController.pinCodeReturnValue = pinCode
        testSetup.keychainController.containsPINCodeReturnValue = true
        
        #expect(testSetup.context.alertInfo == nil)
        #expect(testSetup.appLockService.isEnabled)
        
        // When disabling the PIN code lock.
        testSetup.context.send(viewAction: .disable)
        
        // Then an alert should be shown before disabling it.
        #expect(testSetup.context.alertInfo != nil)
        #expect(testSetup.appLockService.isEnabled)
    }
}

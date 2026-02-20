//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Testing

@Suite(.serialized)
@MainActor
final class AppLockSetupSettingsScreenViewModelTests {
    var appLockService: AppLockServiceProtocol
    var keychainController: KeychainControllerMock
    var viewModel: AppLockSetupSettingsScreenViewModelProtocol
    
    var context: AppLockSetupSettingsScreenViewModelType.Context {
        viewModel.context
    }
    
    init() {
        AppSettings.resetAllSettings()
        keychainController = KeychainControllerMock()
        appLockService = AppLockService(keychainController: keychainController, appSettings: AppSettings())
        viewModel = AppLockSetupSettingsScreenViewModel(appLockService: AppLockServiceMock.mock())
    }
    
    deinit {
        AppSettings.resetAllSettings()
    }

    @Test
    func disablingShowsAlert() {
        // Given a fresh screen with the PIN code enabled.
        let pinCode = "2023"
        keychainController.pinCodeReturnValue = pinCode
        keychainController.containsPINCodeReturnValue = true
        
        #expect(context.alertInfo == nil)
        #expect(appLockService.isEnabled)
        
        // When disabling the PIN code lock.
        context.send(viewAction: .disable)
        
        // Then an alert should be shown before disabling it.
        #expect(context.alertInfo != nil)
        #expect(appLockService.isEnabled)
    }
}

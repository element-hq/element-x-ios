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
final class AppLockSetupBiometricsScreenViewModelTests {
    var appLockService: AppLockServiceMock
    var viewModel: AppLockSetupBiometricsScreenViewModelProtocol
    
    var context: AppLockSetupBiometricsScreenViewModelType.Context {
        viewModel.context
    }
    
    init() {
        AppSettings.resetAllSettings()
        
        appLockService = AppLockServiceMock()
        appLockService.underlyingIsEnabled = true
        appLockService.underlyingBiometryType = .touchID
        appLockService.enableBiometricUnlockReturnValue = .success(())
        viewModel = AppLockSetupBiometricsScreenViewModel(appLockService: appLockService)
    }
    
    deinit {
        AppSettings.resetAllSettings()
    }

    @Test
    func allow() async throws {
        // When allowing Touch/Face ID.
        let deferred = deferFulfillment(viewModel.actions) { $0 == .continue }
        context.send(viewAction: .allow)
        try await deferred.fulfill()
        
        // Then the service should now have biometric unlock enabled.
        #expect(appLockService.enableBiometricUnlockCallsCount == 1)
    }

    @Test
    func skip() async throws {
        // When skipping biometrics.
        let deferred = deferFulfillment(viewModel.actions) { $0 == .continue }
        context.send(viewAction: .skip)
        try await deferred.fulfill()
        
        // Then the service should now have biometric unlock enabled.
        #expect(appLockService.enableBiometricUnlockCallsCount == 0)
    }
}

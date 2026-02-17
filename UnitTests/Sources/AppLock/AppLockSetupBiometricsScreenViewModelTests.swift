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
@Suite(.serialized)
struct AppLockSetupBiometricsScreenViewModelTests {
    @MainActor
    private struct TestSetup {
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
    }

    @Test
    func allow() async throws {
        var testSetup = TestSetup()
        defer { AppSettings.resetAllSettings() }
        
        // When allowing Touch/Face ID.
        let deferred = deferFulfillment(testSetup.viewModel.actions) { $0 == .continue }
        testSetup.context.send(viewAction: .allow)
        try await deferred.fulfill()
        
        // Then the service should now have biometric unlock enabled.
        #expect(testSetup.appLockService.enableBiometricUnlockCallsCount == 1)
    }

    @Test
    func skip() async throws {
        var testSetup = TestSetup()
        defer { AppSettings.resetAllSettings() }
        
        // When skipping biometrics.
        let deferred = deferFulfillment(testSetup.viewModel.actions) { $0 == .continue }
        testSetup.context.send(viewAction: .skip)
        try await deferred.fulfill()
        
        // Then the service should now have biometric unlock enabled.
        #expect(testSetup.appLockService.enableBiometricUnlockCallsCount == 0)
    }
}

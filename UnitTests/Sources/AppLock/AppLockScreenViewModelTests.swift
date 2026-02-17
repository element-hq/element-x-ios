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
struct AppLockScreenViewModelTests {
    @MainActor
    private struct TestSetup {
        var appSettings: AppSettings
        var appLockService: AppLockService
        var keychainController: KeychainControllerMock
        var viewModel: AppLockScreenViewModelProtocol
        
        var context: AppLockScreenViewModelType.Context {
            viewModel.context
        }
        
        init() {
            AppSettings.resetAllSettings()
            appSettings = AppSettings()
            keychainController = KeychainControllerMock()
            appLockService = AppLockService(keychainController: keychainController, appSettings: appSettings)
            viewModel = AppLockScreenViewModel(appLockService: appLockService)
        }
    }
    
    @Test
    func unlock() async throws {
        var testSetup = TestSetup()
        defer { AppSettings.resetAllSettings() }
        
        // Given a valid PIN code.
        let pinCode = "2023"
        testSetup.keychainController.pinCodeReturnValue = pinCode
        testSetup.keychainController.containsPINCodeBiometricStateReturnValue = false
        
        // When entering it on the lock screen.
        let deferred = deferFulfillment(testSetup.viewModel.actions) { $0 == .appUnlocked }
        testSetup.viewModel.context.pinCode = pinCode
        let result = try await deferred.fulfill()
        
        // The app should become unlocked.
        #expect(result == .appUnlocked)
    }
    
    @Test
    func forgotPIN() async throws {
        var testSetup = TestSetup()
        defer { AppSettings.resetAllSettings() }
        
        // Given a fresh launch of the app.
        #expect(testSetup.context.alertInfo == nil, "No alert should be shown initially.")
        
        // When the user has forgotten their PIN.
        testSetup.context.send(viewAction: .forgotPIN)
        
        // Then an alert should be shown before logging out.
        #expect(testSetup.context.alertInfo?.id == .confirmResetPIN, "An alert should be shown before logging out.")
        
        // When confirming the logout.
        let deferred = deferFulfillment(testSetup.viewModel.actions) { $0 == .forceLogout }
        testSetup.context.alertInfo?.primaryButton.action?()
        
        // Then a force logout should be initiated.
        try await deferred.fulfill()
    }
    
    @Test
    func unlockFailure() async throws {
        var testSetup = TestSetup()
        defer { AppSettings.resetAllSettings() }
        
        // Given an invalid PIN code.
        let pinCode = "2024"
        testSetup.keychainController.pinCodeReturnValue = "2023"
        testSetup.keychainController.containsPINCodeBiometricStateReturnValue = false
        #expect(testSetup.context.viewState.numberOfPINAttempts == 0, "The shouldn't be any attempts yet.")
        #expect(!testSetup.context.viewState.isSubtitleWarning, "No warning should be shown yet.")
        #expect(testSetup.context.alertInfo == nil, "No alert should be shown yet.")
        
        // When entering it on the lock screen.
        var deferred = deferFulfillment(testSetup.context.$viewState) { $0.numberOfPINAttempts == 1 }
        testSetup.viewModel.context.pinCode = pinCode
        try await deferred.fulfill()
        testSetup.context.send(viewAction: .clearPINCode) // Simulate the animation completion
        
        // Then a failed attempt should be shown.
        #expect(testSetup.context.viewState.numberOfPINAttempts == 1, "A failed attempt should have been recorded.")
        #expect(testSetup.context.viewState.isSubtitleWarning, "A warning should now be shown.")
        #expect(testSetup.context.alertInfo == nil, "No alert should be shown yet.")
        
        // When entering twice more
        deferred = deferFulfillment(testSetup.context.$viewState) { $0.numberOfPINAttempts == 2 }
        testSetup.viewModel.context.pinCode = pinCode
        try await deferred.fulfill()
        testSetup.context.send(viewAction: .clearPINCode) // Simulate the animation completion
        deferred = deferFulfillment(testSetup.context.$viewState) { $0.numberOfPINAttempts == 3 }
        testSetup.viewModel.context.pinCode = pinCode
        try await deferred.fulfill()
        testSetup.context.send(viewAction: .clearPINCode) // Simulate the animation completion
        
        // Then an alert should be shown
        #expect(testSetup.context.viewState.numberOfPINAttempts == 3, "All the attempts should have been recorded.")
        #expect(testSetup.context.viewState.isSubtitleWarning, "The warning should still be shown.")
        #expect(testSetup.context.alertInfo?.id == .forcedLogout, "An alert should now be shown.")
    }
    
    @Test
    func forceQuitRequiresLogout() async throws {
        var testSetup = TestSetup()
        defer { AppSettings.resetAllSettings() }
        
        // Given an app with a PIN set where the user attempted to unlock 3 times.
        testSetup.keychainController.pinCodeReturnValue = "2023"
        testSetup.keychainController.containsPINCodeBiometricStateReturnValue = false
        testSetup.appSettings.appLockNumberOfPINAttempts = 2
        #expect(testSetup.context.alertInfo == nil)
        let deferred = deferFulfillment(testSetup.context.$viewState) { $0.numberOfPINAttempts == 3 }
        testSetup.viewModel.context.pinCode = "0000"
        try await deferred.fulfill()
        #expect(testSetup.appSettings.appLockNumberOfPINAttempts == 3, "The app should have 3 failed attempts before the force quit.")
        #expect(testSetup.context.alertInfo?.id == .forcedLogout, "The app should be showing the alert before the force quit.")
        
        // When force quitting the app and relaunching.
        let freshViewModel = AppLockScreenViewModel(appLockService: testSetup.appLockService)
        
        // Then the alert should remain in place
        #expect(freshViewModel.context.alertInfo?.id == .forcedLogout, "The new view model from the fresh launch should also show the alert")
    }
}

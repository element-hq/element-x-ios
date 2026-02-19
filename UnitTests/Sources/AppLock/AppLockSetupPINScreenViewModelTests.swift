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
final class AppLockSetupPINScreenViewModelTests {
    var appLockService: AppLockService!
    var keychainController: KeychainControllerMock!
    var viewModel: AppLockSetupPINScreenViewModelProtocol!
    
    var context: AppLockSetupPINScreenViewModelType.Context {
        viewModel.context
    }
    
    deinit {
        AppSettings.resetAllSettings()
    }

    @Test
    func createPIN() async throws {
        setup(mode: .create)
        
        // Given the screen in create mode.
        #expect(context.viewState.mode == .create, "The mode should start as creation.")
        
        // When entering an new PIN.
        let createDeferred = deferFulfillment(context.$viewState) { $0.mode == .confirm }
        context.pinCode = "2023"
        try await createDeferred.fulfill()
        
        // Then the screen should transition to the confirm mode.
        #expect(context.viewState.mode == .confirm, "The mode should transition to confirmation.")
        
        // When re-entering that PIN.
        let confirmDeferred = deferFulfillment(viewModel.actions) { $0 == .complete }
        context.pinCode = "2023"
        
        // Then the screen should signal it is complete.
        try await confirmDeferred.fulfill()
    }
    
    @Test
    func createWeakPIN() async throws {
        setup(mode: .create)
        
        // Given the screen in create mode.
        #expect(context.viewState.mode == .create, "The mode should start as creation.")
        #expect(context.alertInfo == nil, "There shouldn't be an alert to begin with.")
        
        // When entering a weak PIN on the blocklist.
        let deferred = deferFulfillment(context.$viewState) { $0.bindings.alertInfo != nil }
        context.pinCode = "0000"
        try await deferred.fulfill()
        
        // Then the PIN should be rejected and the user alerted.
        #expect(context.alertInfo?.id == .weakPIN, "The weak PIN should be rejected.")
        #expect(context.viewState.mode == .create, "The mode shouldn't transition after an invalid PIN code.")
    }
    
    @Test
    func createPINMismatch() async throws {
        setup(mode: .create)
        
        // Given the confirm mode after entering a new PIN.
        #expect(context.viewState.mode == .create, "The mode should start as creation.")
        #expect(context.alertInfo == nil, "There shouldn't be an alert to begin with.")
        
        let createDeferred = deferFulfillment(context.$viewState) { $0.mode == .confirm }
        context.pinCode = "2023"
        try await createDeferred.fulfill()
        #expect(context.viewState.mode == .confirm, "The mode should transition to confirmation.")
        #expect(context.viewState.numberOfConfirmAttempts == 0, "The mode should start with zero attempts.")
        #expect(context.alertInfo == nil, "There shouldn't be an alert after a valid initial PIN.")
        
        // When entering the new PIN incorrectly
        var deferred = deferFulfillment(context.$viewState) { $0.numberOfConfirmAttempts == 1 }
        context.pinCode = "2024"
        try await deferred.fulfill()
        
        // Then the user should be alerted.
        #expect(context.viewState.numberOfConfirmAttempts == 1, "The mismatch should be counted.")
        #expect(context.alertInfo?.id == .pinMismatch, "A PIN mismatch should be rejected.")
        
        // When dismissing the alert and repeating twice more.
        context.alertInfo?.primaryButton.action?()
        deferred = deferFulfillment(context.$viewState) { $0.numberOfConfirmAttempts == 2 }
        context.pinCode = "2024"
        try await deferred.fulfill()
        context.alertInfo?.primaryButton.action?()
        deferred = deferFulfillment(context.$viewState) { $0.numberOfConfirmAttempts == 3 }
        context.pinCode = "2024"
        try await deferred.fulfill()
        #expect(context.viewState.numberOfConfirmAttempts == 3, "All the mismatches should be counted.")
        #expect(context.alertInfo?.id == .pinMismatch, "A PIN mismatch should be rejected.")
        
        // Then tapping the alert button should reset back to create mode.
        context.alertInfo?.primaryButton.action?()
        #expect(context.viewState.mode == .create, "The mode should revert back to creation.")
    }
    
    @Test
    func unlock() async throws {
        setup(mode: .unlock)
        
        // Given the screen in unlock mode.
        let pinCode = "2023"
        keychainController.pinCodeReturnValue = pinCode
        keychainController.containsPINCodeReturnValue = true
        keychainController.containsPINCodeBiometricStateReturnValue = false
        
        // When entering the configured PIN.
        let deferred = deferFulfillment(viewModel.actions) { $0 == .complete }
        context.pinCode = pinCode
        
        // Then the screen should signal it is complete.
        try await deferred.fulfill()
    }
    
    @Test
    func forgotPIN() async throws {
        setup(mode: .unlock)
        
        // Given the screen in unlock mode.
        #expect(context.alertInfo == nil, "There shouldn't be an alert to begin with.")
        #expect(!context.viewState.isLoggingOut, "The view should not start disabled.")
        
        // When the user has forgotten their PIN.
        context.send(viewAction: .forgotPIN)
        
        // Then an alert should be shown before logging out.
        #expect(context.alertInfo?.id == .confirmResetPIN, "The weak PIN should be rejected.")
        #expect(!context.viewState.isLoggingOut, "The view should not be disabled until the user confirms.")
        
        // When confirming the logout.
        let deferred = deferFulfillment(viewModel.actions) { $0 == .forceLogout }
        context.alertInfo?.primaryButton.action?()
        
        // Then a force logout should be initiated.
        try await deferred.fulfill()
        #expect(context.viewState.isLoggingOut, "The view should become disabled.")
    }
    
    @Test
    func unlockFailed() async throws {
        setup(mode: .unlock)
        
        // Given the screen in unlock mode.
        keychainController.pinCodeReturnValue = "2023"
        keychainController.containsPINCodeReturnValue = true
        keychainController.containsPINCodeBiometricStateReturnValue = false
        #expect(context.viewState.numberOfUnlockAttempts == 0, "The screen should start with zero attempts.")
        #expect(!context.viewState.isSubtitleWarning, "The subtitle should start without a warning.")
        #expect(!context.viewState.isLoggingOut, "The view should not start disabled.")
        
        // When entering a different PIN.
        var deferred = deferFulfillment(context.$viewState, keyPath: \.bindings.pinCode, transitionValues: ["", "2024", ""])
        context.pinCode = "2024"
        try await deferred.fulfill()
        
        // Then the PIN should be rejected and the user notified.
        #expect(context.viewState.numberOfUnlockAttempts == 1, "An invalid attempt should be counted.")
        #expect(context.viewState.isSubtitleWarning, "The subtitle should then show a warning.")
        #expect(!context.viewState.isLoggingOut, "The view should still work.")
        
        // When entering the same incorrect PIN twice more
        deferred = deferFulfillment(context.$viewState, keyPath: \.bindings.pinCode, transitionValues: ["", "2024", ""])
        context.pinCode = "2024"
        try await deferred.fulfill()
        deferred = deferFulfillment(context.$viewState, keyPath: \.bindings.pinCode, transitionValues: ["", "2024", ""])
        context.pinCode = "2024"
        try await deferred.fulfill()
        
        // Then the user should be alerted that they're being signed out.
        #expect(context.viewState.numberOfUnlockAttempts == 3, "All invalid attempts should be counted.")
        #expect(context.viewState.isSubtitleWarning, "The subtitle should continue showing a warning.")
        #expect(context.alertInfo?.id == .forceLogout, "An alert should be shown about a force logout.")
        #expect(context.viewState.isLoggingOut, "The view should become disabled.")
    }
    
    // MARK: - Helpers
    
    private func setup(mode: AppLockSetupPINScreenMode) {
        AppSettings.resetAllSettings()
        keychainController = KeychainControllerMock()
        appLockService = AppLockService(keychainController: keychainController, appSettings: AppSettings())
        viewModel = AppLockSetupPINScreenViewModel(initialMode: mode, isMandatory: false, appLockService: appLockService)
    }
}

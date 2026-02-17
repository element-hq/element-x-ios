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
struct AppLockSetupPINScreenViewModelTests {
    @MainActor
    private final class TestSetup {
        var appLockService: AppLockService
        var keychainController: KeychainControllerMock
        var viewModel: AppLockSetupPINScreenViewModelProtocol
        
        var context: AppLockSetupPINScreenViewModelType.Context {
            viewModel.context
        }
        
        init(mode: AppLockSetupPINScreenMode) {
            AppSettings.resetAllSettings()
            keychainController = KeychainControllerMock()
            appLockService = AppLockService(keychainController: keychainController, appSettings: AppSettings())
            viewModel = AppLockSetupPINScreenViewModel(initialMode: mode, isMandatory: false, appLockService: appLockService)
        }
        
        deinit {
            AppSettings.resetAllSettings()
        }
    }

    @Test
    func createPIN() async throws {
        let testSetup = TestSetup(mode: .create)
        
        // Given the screen in create mode.
        #expect(testSetup.context.viewState.mode == .create, "The mode should start as creation.")
        
        // When entering an new PIN.
        let createDeferred = deferFulfillment(testSetup.context.$viewState) { $0.mode == .confirm }
        testSetup.context.pinCode = "2023"
        try await createDeferred.fulfill()
        
        // Then the screen should transition to the confirm mode.
        #expect(testSetup.context.viewState.mode == .confirm, "The mode should transition to confirmation.")
        
        // When re-entering that PIN.
        let confirmDeferred = deferFulfillment(testSetup.viewModel.actions) { $0 == .complete }
        testSetup.context.pinCode = "2023"
        
        // Then the screen should signal it is complete.
        try await confirmDeferred.fulfill()
    }
    
    @Test
    func createWeakPIN() async throws {
        let testSetup = TestSetup(mode: .create)
        
        // Given the screen in create mode.
        #expect(testSetup.context.viewState.mode == .create, "The mode should start as creation.")
        #expect(testSetup.context.alertInfo == nil, "There shouldn't be an alert to begin with.")
        
        // When entering a weak PIN on the blocklist.
        let deferred = deferFulfillment(testSetup.context.$viewState) { $0.bindings.alertInfo != nil }
        testSetup.context.pinCode = "0000"
        try await deferred.fulfill()
        
        // Then the PIN should be rejected and the user alerted.
        #expect(testSetup.context.alertInfo?.id == .weakPIN, "The weak PIN should be rejected.")
        #expect(testSetup.context.viewState.mode == .create, "The mode shouldn't transition after an invalid PIN code.")
    }
    
    @Test
    func createPINMismatch() async throws {
        let testSetup = TestSetup(mode: .create)
        
        // Given the confirm mode after entering a new PIN.
        #expect(testSetup.context.viewState.mode == .create, "The mode should start as creation.")
        #expect(testSetup.context.alertInfo == nil, "There shouldn't be an alert to begin with.")
        
        let createDeferred = deferFulfillment(testSetup.context.$viewState) { $0.mode == .confirm }
        testSetup.context.pinCode = "2023"
        try await createDeferred.fulfill()
        #expect(testSetup.context.viewState.mode == .confirm, "The mode should transition to confirmation.")
        #expect(testSetup.context.viewState.numberOfConfirmAttempts == 0, "The mode should start with zero attempts.")
        #expect(testSetup.context.alertInfo == nil, "There shouldn't be an alert after a valid initial PIN.")
        
        // When entering the new PIN incorrectly
        var deferred = deferFulfillment(testSetup.context.$viewState) { $0.numberOfConfirmAttempts == 1 }
        testSetup.context.pinCode = "2024"
        try await deferred.fulfill()
        
        // Then the user should be alerted.
        #expect(testSetup.context.viewState.numberOfConfirmAttempts == 1, "The mismatch should be counted.")
        #expect(testSetup.context.alertInfo?.id == .pinMismatch, "A PIN mismatch should be rejected.")
        
        // When dismissing the alert and repeating twice more.
        testSetup.context.alertInfo?.primaryButton.action?()
        deferred = deferFulfillment(testSetup.context.$viewState) { $0.numberOfConfirmAttempts == 2 }
        testSetup.context.pinCode = "2024"
        try await deferred.fulfill()
        testSetup.context.alertInfo?.primaryButton.action?()
        deferred = deferFulfillment(testSetup.context.$viewState) { $0.numberOfConfirmAttempts == 3 }
        testSetup.context.pinCode = "2024"
        try await deferred.fulfill()
        #expect(testSetup.context.viewState.numberOfConfirmAttempts == 3, "All the mismatches should be counted.")
        #expect(testSetup.context.alertInfo?.id == .pinMismatch, "A PIN mismatch should be rejected.")
        
        // Then tapping the alert button should reset back to create mode.
        testSetup.context.alertInfo?.primaryButton.action?()
        #expect(testSetup.context.viewState.mode == .create, "The mode should revert back to creation.")
    }
    
    @Test
    func unlock() async throws {
        let testSetup = TestSetup(mode: .unlock)
        
        // Given the screen in unlock mode.
        let pinCode = "2023"
        testSetup.keychainController.pinCodeReturnValue = pinCode
        testSetup.keychainController.containsPINCodeReturnValue = true
        testSetup.keychainController.containsPINCodeBiometricStateReturnValue = false
        
        // When entering the configured PIN.
        let deferred = deferFulfillment(testSetup.viewModel.actions) { $0 == .complete }
        testSetup.context.pinCode = pinCode
        
        // Then the screen should signal it is complete.
        try await deferred.fulfill()
    }
    
    @Test
    func forgotPIN() async throws {
        let testSetup = TestSetup(mode: .unlock)
        
        // Given the screen in unlock mode.
        #expect(testSetup.context.alertInfo == nil, "There shouldn't be an alert to begin with.")
        #expect(!testSetup.context.viewState.isLoggingOut, "The view should not start disabled.")
        
        // When the user has forgotten their PIN.
        testSetup.context.send(viewAction: .forgotPIN)
        
        // Then an alert should be shown before logging out.
        #expect(testSetup.context.alertInfo?.id == .confirmResetPIN, "The weak PIN should be rejected.")
        #expect(!testSetup.context.viewState.isLoggingOut, "The view should not be disabled until the user confirms.")
        
        // When confirming the logout.
        let deferred = deferFulfillment(testSetup.viewModel.actions) { $0 == .forceLogout }
        testSetup.context.alertInfo?.primaryButton.action?()
        
        // Then a force logout should be initiated.
        try await deferred.fulfill()
        #expect(testSetup.context.viewState.isLoggingOut, "The view should become disabled.")
    }
    
    @Test
    func unlockFailed() async throws {
        let testSetup = TestSetup(mode: .unlock)
        
        // Given the screen in unlock mode.
        testSetup.keychainController.pinCodeReturnValue = "2023"
        testSetup.keychainController.containsPINCodeReturnValue = true
        testSetup.keychainController.containsPINCodeBiometricStateReturnValue = false
        #expect(testSetup.context.viewState.numberOfUnlockAttempts == 0, "The screen should start with zero attempts.")
        #expect(!testSetup.context.viewState.isSubtitleWarning, "The subtitle should start without a warning.")
        #expect(!testSetup.context.viewState.isLoggingOut, "The view should not start disabled.")
        
        // When entering a different PIN.
        var deferred = deferFulfillment(testSetup.context.$viewState, keyPath: \.bindings.pinCode, transitionValues: ["", "2024", ""])
        testSetup.context.pinCode = "2024"
        try await deferred.fulfill()
        
        // Then the PIN should be rejected and the user notified.
        #expect(testSetup.context.viewState.numberOfUnlockAttempts == 1, "An invalid attempt should be counted.")
        #expect(testSetup.context.viewState.isSubtitleWarning, "The subtitle should then show a warning.")
        #expect(!testSetup.context.viewState.isLoggingOut, "The view should still work.")
        
        // When entering the same incorrect PIN twice more
        deferred = deferFulfillment(testSetup.context.$viewState, keyPath: \.bindings.pinCode, transitionValues: ["", "2024", ""])
        testSetup.context.pinCode = "2024"
        try await deferred.fulfill()
        deferred = deferFulfillment(testSetup.context.$viewState, keyPath: \.bindings.pinCode, transitionValues: ["", "2024", ""])
        testSetup.context.pinCode = "2024"
        try await deferred.fulfill()
        
        // Then the user should be alerted that they're being signed out.
        #expect(testSetup.context.viewState.numberOfUnlockAttempts == 3, "All invalid attempts should be counted.")
        #expect(testSetup.context.viewState.isSubtitleWarning, "The subtitle should continue showing a warning.")
        #expect(testSetup.context.alertInfo?.id == .forceLogout, "An alert should be shown about a force logout.")
        #expect(testSetup.context.viewState.isLoggingOut, "The view should become disabled.")
    }
}

//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import XCTest

@testable import ElementX

@MainActor
class AppLockSetupPINScreenViewModelTests: XCTestCase {
    var appLockService: AppLockService!
    var keychainController: KeychainControllerMock!
    var viewModel: AppLockSetupPINScreenViewModelProtocol!
    
    var context: AppLockSetupPINScreenViewModelType.Context { viewModel.context }
    
    override func setUp() {
        AppSettings.resetAllSettings()
        keychainController = KeychainControllerMock()
        appLockService = AppLockService(keychainController: keychainController, appSettings: AppSettings())
    }
    
    override func tearDown() {
        AppSettings.resetAllSettings()
    }

    func testCreatePIN() async throws {
        // Given the screen in create mode.
        viewModel = AppLockSetupPINScreenViewModel(initialMode: .create, isMandatory: false, appLockService: appLockService)
        XCTAssertEqual(context.viewState.mode, .create, "The mode should start as creation.")
        
        // When entering an new PIN.
        let createDeferred = deferFulfillment(context.$viewState, message: "A valid PIN needs confirming.") { $0.mode == .confirm }
        context.pinCode = "2023"
        try await createDeferred.fulfill()
        
        // Then the screen should transition to the confirm mode.
        XCTAssertEqual(context.viewState.mode, .confirm, "The mode should transition to confirmation.")
        
        // When re-entering that PIN.
        let confirmDeferred = deferFulfillment(viewModel.actions, message: "The screen should be finished.") { $0 == .complete }
        context.pinCode = "2023"
        
        // Then the screen should signal it is complete.
        try await confirmDeferred.fulfill()
    }
    
    func testCreateWeakPIN() async throws {
        // Given the screen in create mode.
        viewModel = AppLockSetupPINScreenViewModel(initialMode: .create, isMandatory: false, appLockService: appLockService)
        XCTAssertEqual(context.viewState.mode, .create, "The mode should start as creation.")
        XCTAssertNil(context.alertInfo, "There shouldn't be an alert to begin with.")
        
        // When entering a weak PIN on the blocklist.
        let deferred = deferFulfillment(context.$viewState) { $0.bindings.alertInfo != nil }
        context.pinCode = "0000"
        try await deferred.fulfill()
        
        // Then the PIN should be rejected and the user alerted.
        XCTAssertEqual(context.alertInfo?.id, .weakPIN, "The weak PIN should be rejected.")
        XCTAssertEqual(context.viewState.mode, .create, "The mode shouldn't transition after an invalid PIN code.")
    }
    
    func testCreatePINMismatch() async throws {
        // Given the confirm mode after entering a new PIN.
        viewModel = AppLockSetupPINScreenViewModel(initialMode: .create, isMandatory: false, appLockService: appLockService)
        XCTAssertEqual(context.viewState.mode, .create, "The mode should start as creation.")
        XCTAssertNil(context.alertInfo, "There shouldn't be an alert to begin with.")
        
        let createDeferred = deferFulfillment(context.$viewState, message: "A valid PIN needs confirming.") { $0.mode == .confirm }
        context.pinCode = "2023"
        try await createDeferred.fulfill()
        XCTAssertEqual(context.viewState.mode, .confirm, "The mode should transition to confirmation.")
        XCTAssertEqual(context.viewState.numberOfConfirmAttempts, 0, "The mode should start with zero attempts.")
        XCTAssertNil(context.alertInfo, "There shouldn't be an alert after a valid initial PIN.")
        
        // When entering the new PIN incorrectly
        var deferred = deferFulfillment(context.$viewState) { $0.numberOfConfirmAttempts == 1 }
        context.pinCode = "2024"
        try await deferred.fulfill()
        
        // Then the user should be alerted.
        XCTAssertEqual(context.viewState.numberOfConfirmAttempts, 1, "The mismatch should be counted.")
        XCTAssertEqual(context.alertInfo?.id, .pinMismatch, "A PIN mismatch should be rejected.")
        
        // When dismissing the alert and repeating twice more.
        context.alertInfo?.primaryButton.action?()
        deferred = deferFulfillment(context.$viewState) { $0.numberOfConfirmAttempts == 2 }
        context.pinCode = "2024"
        try await deferred.fulfill()
        context.alertInfo?.primaryButton.action?()
        deferred = deferFulfillment(context.$viewState) { $0.numberOfConfirmAttempts == 3 }
        context.pinCode = "2024"
        try await deferred.fulfill()
        XCTAssertEqual(context.viewState.numberOfConfirmAttempts, 3, "All the mismatches should be counted.")
        XCTAssertEqual(context.alertInfo?.id, .pinMismatch, "A PIN mismatch should be rejected.")
        
        // Then tapping the alert button should reset back to create mode.
        context.alertInfo?.primaryButton.action?()
        XCTAssertEqual(context.viewState.mode, .create, "The mode should revert back to creation.")
    }
    
    func testUnlock() async throws {
        // Given the screen in unlock mode.
        viewModel = AppLockSetupPINScreenViewModel(initialMode: .unlock, isMandatory: false, appLockService: appLockService)
        let pinCode = "2023"
        keychainController.pinCodeReturnValue = pinCode
        keychainController.containsPINCodeReturnValue = true
        keychainController.containsPINCodeBiometricStateReturnValue = false
        
        // When entering the configured PIN.
        let deferred = deferFulfillment(viewModel.actions, message: "The screen should be finished.") { $0 == .complete }
        context.pinCode = pinCode
        
        // Then the screen should signal it is complete.
        try await deferred.fulfill()
    }
    
    func testForgotPIN() async throws {
        // Given the screen in unlock mode.
        viewModel = AppLockSetupPINScreenViewModel(initialMode: .unlock, isMandatory: false, appLockService: appLockService)
        XCTAssertNil(context.alertInfo, "There shouldn't be an alert to begin with.")
        XCTAssertFalse(context.viewState.isLoggingOut, "The view should not start disabled.")
        
        // When the user has forgotten their PIN.
        context.send(viewAction: .forgotPIN)
        
        // Then an alert should be shown before logging out.
        XCTAssertEqual(context.alertInfo?.id, .confirmResetPIN, "The weak PIN should be rejected.")
        XCTAssertFalse(context.viewState.isLoggingOut, "The view should not be disabled until the user confirms.")
        
        // When confirming the logout.
        let deferred = deferFulfillment(viewModel.actions) { $0 == .forceLogout }
        context.alertInfo?.primaryButton.action?()
        
        // Then a force logout should be initiated.
        try await deferred.fulfill()
        XCTAssertTrue(context.viewState.isLoggingOut, "The view should become disabled.")
    }
    
    func testUnlockFailed() async throws {
        // Given the screen in unlock mode.
        viewModel = AppLockSetupPINScreenViewModel(initialMode: .unlock, isMandatory: false, appLockService: appLockService)
        keychainController.pinCodeReturnValue = "2023"
        keychainController.containsPINCodeReturnValue = true
        keychainController.containsPINCodeBiometricStateReturnValue = false
        XCTAssertEqual(context.viewState.numberOfUnlockAttempts, 0, "The screen should start with zero attempts.")
        XCTAssertFalse(context.viewState.isSubtitleWarning, "The subtitle should start without a warning.")
        XCTAssertFalse(context.viewState.isLoggingOut, "The view should not start disabled.")
        
        // When entering a different PIN.
        var deferred = deferFulfillment(context.$viewState, keyPath: \.bindings.pinCode, transitionValues: ["", "2024", ""],
                                        message: "The PIN should be entered and then cleared by the view model.")
        context.pinCode = "2024"
        try await deferred.fulfill()
        
        // Then the PIN should be rejected and the user notified.
        XCTAssertEqual(context.viewState.numberOfUnlockAttempts, 1, "An invalid attempt should be counted.")
        XCTAssertTrue(context.viewState.isSubtitleWarning, "The subtitle should then show a warning.")
        XCTAssertFalse(context.viewState.isLoggingOut, "The view should still work.")
        
        // When entering the same incorrect PIN twice more
        deferred = deferFulfillment(context.$viewState, keyPath: \.bindings.pinCode, transitionValues: ["", "2024", ""],
                                    message: "The PIN should be entered and then cleared by the view model.")
        context.pinCode = "2024"
        try await deferred.fulfill()
        deferred = deferFulfillment(context.$viewState, keyPath: \.bindings.pinCode, transitionValues: ["", "2024", ""],
                                    message: "The PIN should be entered and then cleared by the view model.")
        context.pinCode = "2024"
        try await deferred.fulfill()
        
        // Then the user should be alerted that they're being signed out.
        XCTAssertEqual(context.viewState.numberOfUnlockAttempts, 3, "All invalid attempts should be counted.")
        XCTAssertTrue(context.viewState.isSubtitleWarning, "The subtitle should continue showing a warning.")
        XCTAssertEqual(context.alertInfo?.id, .forceLogout, "An alert should be shown about a force logout.")
        XCTAssertTrue(context.viewState.isLoggingOut, "The view should become disabled.")
    }
}

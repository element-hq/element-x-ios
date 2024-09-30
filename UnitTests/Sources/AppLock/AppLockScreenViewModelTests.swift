//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import XCTest

@testable import ElementX

@MainActor
class AppLockScreenViewModelTests: XCTestCase {
    var appSettings: AppSettings!
    var appLockService: AppLockService!
    var keychainController: KeychainControllerMock!
    var viewModel: AppLockScreenViewModelProtocol!
    
    var context: AppLockScreenViewModelType.Context { viewModel.context }
    
    override func setUp() {
        AppSettings.resetAllSettings()
        appSettings = AppSettings()
        keychainController = KeychainControllerMock()
        appLockService = AppLockService(keychainController: keychainController, appSettings: appSettings)
        viewModel = AppLockScreenViewModel(appLockService: appLockService)
    }
    
    override func tearDown() {
        AppSettings.resetAllSettings()
    }
    
    func testUnlock() async throws {
        // Given a valid PIN code.
        let pinCode = "2023"
        keychainController.pinCodeReturnValue = pinCode
        keychainController.containsPINCodeBiometricStateReturnValue = false
        
        // When entering it on the lock screen.
        let deferred = deferFulfillment(viewModel.actions) { $0 == .appUnlocked }
        viewModel.context.pinCode = pinCode
        let result = try await deferred.fulfill()
        
        // The app should become unlocked.
        XCTAssertEqual(result, .appUnlocked)
    }
    
    func testForgotPIN() async throws {
        // Given a fresh launch of the app.
        XCTAssertNil(context.alertInfo, "No alert should be shown initially.")
        
        // When the user has forgotten their PIN.
        context.send(viewAction: .forgotPIN)
        
        // Then an alert should be shown before logging out.
        XCTAssertEqual(context.alertInfo?.id, .confirmResetPIN, "An alert should be shown before logging out.")
        
        // When confirming the logout.
        let deferred = deferFulfillment(viewModel.actions) { $0 == .forceLogout }
        context.alertInfo?.primaryButton.action?()
        
        // Then a force logout should be initiated.
        try await deferred.fulfill()
    }
    
    func testUnlockFailure() async throws {
        // Given an invalid PIN code.
        let pinCode = "2024"
        keychainController.pinCodeReturnValue = "2023"
        keychainController.containsPINCodeBiometricStateReturnValue = false
        XCTAssertEqual(context.viewState.numberOfPINAttempts, 0, "The shouldn't be any attempts yet.")
        XCTAssertFalse(context.viewState.isSubtitleWarning, "No warning should be shown yet.")
        XCTAssertNil(context.alertInfo, "No alert should be shown yet.")
        
        // When entering it on the lock screen.
        var deferred = deferFulfillment(context.$viewState) { $0.numberOfPINAttempts == 1 }
        viewModel.context.pinCode = pinCode
        try await deferred.fulfill()
        context.send(viewAction: .clearPINCode) // Simulate the animation completion
        
        // Then a failed attempt should be shown.
        XCTAssertEqual(context.viewState.numberOfPINAttempts, 1, "A failed attempt should have been recorded.")
        XCTAssertTrue(context.viewState.isSubtitleWarning, "A warning should now be shown.")
        XCTAssertNil(context.alertInfo, "No alert should be shown yet.")
        
        // When entering twice more
        deferred = deferFulfillment(context.$viewState) { $0.numberOfPINAttempts == 2 }
        viewModel.context.pinCode = pinCode
        try await deferred.fulfill()
        context.send(viewAction: .clearPINCode) // Simulate the animation completion
        deferred = deferFulfillment(context.$viewState) { $0.numberOfPINAttempts == 3 }
        viewModel.context.pinCode = pinCode
        try await deferred.fulfill()
        context.send(viewAction: .clearPINCode) // Simulate the animation completion
        
        // Then an alert should be shown
        XCTAssertEqual(context.viewState.numberOfPINAttempts, 3, "All the attempts should have been recorded.")
        XCTAssertTrue(context.viewState.isSubtitleWarning, "The warning should still be shown.")
        XCTAssertEqual(context.alertInfo?.id, .forcedLogout, "An alert should now be shown.")
    }
    
    func testForceQuitRequiresLogout() async throws {
        // Given an app with a PIN set where the user attempted to unlock 3 times.
        keychainController.pinCodeReturnValue = "2023"
        keychainController.containsPINCodeBiometricStateReturnValue = false
        appSettings.appLockNumberOfPINAttempts = 2
        XCTAssertNil(context.alertInfo)
        let deferred = deferFulfillment(context.$viewState) { $0.numberOfPINAttempts == 3 }
        viewModel.context.pinCode = "0000"
        try await deferred.fulfill()
        XCTAssertEqual(appSettings.appLockNumberOfPINAttempts, 3, "The app should have 3 failed attempts before the force quit.")
        XCTAssertEqual(context.alertInfo?.id, .forcedLogout, "The app should be showing the alert before the force quit.")
        
        // When force quitting the app and relaunching.
        viewModel = nil
        let freshViewModel = AppLockScreenViewModel(appLockService: appLockService)
        
        // Then the alert should remain in place
        XCTAssertEqual(freshViewModel.context.alertInfo?.id, .forcedLogout, "The new view model from the fresh launch should also show the alert")
    }
}

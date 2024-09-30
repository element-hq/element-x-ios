//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import XCTest

@testable import ElementX

@MainActor
class AppLockSetupBiometricsScreenViewModelTests: XCTestCase {
    var appLockService: AppLockServiceMock!
    var viewModel: AppLockSetupBiometricsScreenViewModelProtocol!
    
    var context: AppLockSetupBiometricsScreenViewModelType.Context { viewModel.context }
    
    override func setUp() {
        AppSettings.resetAllSettings()
        
        appLockService = AppLockServiceMock()
        appLockService.underlyingIsEnabled = true
        appLockService.underlyingBiometryType = .touchID
        appLockService.enableBiometricUnlockReturnValue = .success(())
        viewModel = AppLockSetupBiometricsScreenViewModel(appLockService: appLockService)
    }
    
    override func tearDown() {
        AppSettings.resetAllSettings()
    }

    func testAllow() async throws {
        // When allowing Touch/Face ID.
        let deferred = deferFulfillment(viewModel.actions) { $0 == .continue }
        context.send(viewAction: .allow)
        try await deferred.fulfill()
        
        // Then the service should now have biometric unlock enabled.
        XCTAssertEqual(appLockService.enableBiometricUnlockCallsCount, 1)
    }

    func testSkip() async throws {
        // When skipping biometrics.
        let deferred = deferFulfillment(viewModel.actions) { $0 == .continue }
        context.send(viewAction: .skip)
        try await deferred.fulfill()
        
        // Then the service should now have biometric unlock enabled.
        XCTAssertEqual(appLockService.enableBiometricUnlockCallsCount, 0)
    }
}

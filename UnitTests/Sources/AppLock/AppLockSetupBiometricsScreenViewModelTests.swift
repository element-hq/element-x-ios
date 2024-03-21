//
// Copyright 2022 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
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

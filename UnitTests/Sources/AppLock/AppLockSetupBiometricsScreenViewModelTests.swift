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
    var appLockService: AppLockService!
    var keychainController: KeychainController!
    var viewModel: AppLockSetupBiometricsScreenViewModelProtocol!
    
    var context: AppLockSetupBiometricsScreenViewModelType.Context { viewModel.context }
    
    override func setUp() {
        AppSettings.reset()
        
        keychainController = KeychainController(service: .tests, accessGroup: InfoPlistReader.main.keychainAccessGroupIdentifier)
        keychainController.resetSecrets()
        
        let context = LAContextMock()
        context.biometryTypeValue = .touchID
        context.evaluatedPolicyDomainStateValue = "👆".data(using: .utf8)
        
        appLockService = AppLockService(keychainController: keychainController, appSettings: AppSettings(), context: context)
        viewModel = AppLockSetupBiometricsScreenViewModel(appLockService: appLockService)
    }
    
    override func tearDown() {
        AppSettings.reset()
    }

    func testAllow() async {
        // Given a service that has biometric unlock disabled.
        guard case .success = appLockService.setupPINCode("2023") else {
            XCTFail("The PIN should be valid.")
            return
        }
        XCTAssertTrue(appLockService.isEnabled)
        XCTAssertFalse(appLockService.biometricUnlockEnabled)
        
        // When allowing Touch/Face ID.
        context.send(viewAction: .allow)
        await Task.yield()
        
        // Then the service should now have biometric unlock enabled.
        XCTAssertTrue(appLockService.biometricUnlockEnabled)
    }

    func testSkip() {
        // Given a service that has biometric unlock disabled.
        guard case .success = appLockService.setupPINCode("2023") else {
            XCTFail("The PIN should be valid.")
            return
        }
        XCTAssertTrue(appLockService.isEnabled)
        XCTAssertFalse(appLockService.biometricUnlockEnabled)
        
        // When skipping biometrics.
        context.send(viewAction: .skip)
        
        // Then the service should now have biometric unlock enabled.
        XCTAssertFalse(appLockService.biometricUnlockEnabled)
    }
}

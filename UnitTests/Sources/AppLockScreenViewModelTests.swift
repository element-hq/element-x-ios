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
class AppLockScreenViewModelTests: XCTestCase {
    var appLockService: AppLockService!
    var viewModel: AppLockScreenViewModelProtocol!
    
    var context: AppLockScreenViewModelType.Context { viewModel.context }
    
    override func setUp() {
        AppSettings.reset()
        appLockService = AppLockService(keychainController: KeychainControllerMock(), appSettings: AppSettings())
        viewModel = AppLockScreenViewModel(appLockService: appLockService)
    }
    
    func testUnlock() async throws {
        // Given a valid PIN code.
        let pinCode = "0000"
        
        // When entering it on the lock screen.
        let deferred = deferFulfillment(viewModel.actions) { $0 == .appUnlocked }
        context.send(viewAction: .submitPINCode(pinCode))
        let result = try await deferred.fulfill()
        
        // The app should become unlocked.
        XCTAssertEqual(result, .appUnlocked)
    }
}

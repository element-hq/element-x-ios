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
class AppLockSetupPINScreenViewModelTests: XCTestCase {
    var appLockService: AppLockService!
    var keychainController: KeychainControllerMock!
    var viewModel: AppLockSetupPINScreenViewModelProtocol!
    
    var context: AppLockSetupPINScreenViewModelType.Context { viewModel.context }
    
    override func setUp() {
        AppSettings.reset()
        keychainController = KeychainControllerMock()
        appLockService = AppLockService(keychainController: keychainController, appSettings: AppSettings())
    }
    
    override func tearDown() {
        AppSettings.reset()
    }

    func testCreatePIN() async throws {
        viewModel = AppLockSetupPINScreenViewModel(initialMode: .create, isMandatory: false, appLockService: appLockService)
        XCTAssertEqual(context.viewState.mode, .create, "The mode should start as creation.")
        
        let createDeferred = deferFulfillment(context.$viewState, message: "A valid PIN needs confirming.") { $0.mode == .confirm }
        context.pinCode = "2023"
        context.send(viewAction: .submitPINCode)
        try await createDeferred.fulfill()
        XCTAssertEqual(context.viewState.mode, .confirm, "The mode should transition to confirmation.")
        
        let confirmDeferred = deferFulfillment(viewModel.actions, message: "The screen should be finished.") { $0 == .complete }
        context.pinCode = "2023"
        context.send(viewAction: .submitPINCode)
        try await confirmDeferred.fulfill()
    }
    
    func testCreateWeakPIN() async throws {
        viewModel = AppLockSetupPINScreenViewModel(initialMode: .create, isMandatory: false, appLockService: appLockService)
        XCTAssertEqual(context.viewState.mode, .create, "The mode should start as creation.")
        XCTAssertNil(context.alertInfo, "There shouldn't be an alert to begin with.")
        
        context.pinCode = "0000"
        context.send(viewAction: .submitPINCode)
        
        XCTAssertEqual(context.alertInfo?.id, .weakPIN, "The weak PIN should be rejected.")
        XCTAssertEqual(context.viewState.mode, .create, "The mode shouldn't transition after an invalid PIN code.")
    }
    
    func testCreatePINMismatch() async throws {
        viewModel = AppLockSetupPINScreenViewModel(initialMode: .create, isMandatory: false, appLockService: appLockService)
        XCTAssertEqual(context.viewState.mode, .create, "The mode should start as creation.")
        XCTAssertNil(context.alertInfo, "There shouldn't be an alert to begin with.")
        
        let createDeferred = deferFulfillment(context.$viewState, message: "A valid PIN needs confirming.") { $0.mode == .confirm }
        context.pinCode = "2023"
        context.send(viewAction: .submitPINCode)
        try await createDeferred.fulfill()
        XCTAssertEqual(context.viewState.mode, .confirm, "The mode should transition to confirmation.")
        XCTAssertNil(context.alertInfo, "There shouldn't be an alert after a valid initial PIN.")
        
        context.pinCode = "2024"
        context.send(viewAction: .submitPINCode)
        
        XCTAssertEqual(context.alertInfo?.id, .pinMismatch, "A PIN mismatch should be rejected.")
    }
    
    func testUnlock() async throws {
        viewModel = AppLockSetupPINScreenViewModel(initialMode: .unlock, isMandatory: false, appLockService: appLockService)
        let pinCode = "2023"
        keychainController.pinCodeReturnValue = pinCode
        keychainController.containsPINCodeReturnValue = true
        
        let deferred = deferFulfillment(viewModel.actions, message: "The screen should be finished.") { $0 == .complete }
        context.pinCode = pinCode
        context.send(viewAction: .submitPINCode)
        try await deferred.fulfill()
    }
}

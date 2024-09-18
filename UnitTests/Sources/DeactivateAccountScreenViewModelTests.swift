//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import XCTest

@testable import ElementX

@MainActor
class DeactivateAccountScreenViewModelTests: XCTestCase {
    var clientProxy: ClientProxyMock!
    var viewModel: DeactivateAccountScreenViewModelProtocol!
    
    var context: DeactivateAccountScreenViewModelType.Context {
        viewModel.context
    }
    
    override func setUpWithError() throws {
        clientProxy = ClientProxyMock(.init())
        viewModel = DeactivateAccountScreenViewModel(clientProxy: clientProxy, userIndicatorController: UserIndicatorControllerMock())
    }
    
    func testDeactivate() async throws {
        try await validateDeactivate(erasingData: false)
    }
    
    func testDeactivateAndErase() async throws {
        try await validateDeactivate(erasingData: true)
    }
    
    func validateDeactivate(erasingData shouldErase: Bool) async throws {
        let enteredPassword = UUID().uuidString
        
        clientProxy.deactivateAccountPasswordEraseDataClosure = { [weak self] password, eraseData in
            guard let self else { return .failure(.sdkError(ClientProxyMockError.generic)) }
            
            if clientProxy.deactivateAccountPasswordEraseDataCallsCount == 1 {
                if password != nil {
                    XCTFail("The password shouldn't be sent first time round.")
                }
                if eraseData != shouldErase {
                    XCTFail("The erase parameter is unexpected.")
                }
                return .failure(.sdkError(ClientProxyMockError.generic))
            } else {
                if password != enteredPassword {
                    XCTFail("The password should match the user's input on the second call.")
                }
                if eraseData != shouldErase {
                    XCTFail("The erase parameter is unexpected.")
                }
                return .success(())
            }
        }
        
        context.eraseData = shouldErase
        context.password = enteredPassword
        
        XCTAssertNil(context.alertInfo)
        
        let deferredState = deferFulfillment(context.$viewState) { $0.bindings.alertInfo != nil }
        context.send(viewAction: .deactivate)
        try await deferredState.fulfill()
        
        guard let confirmationAction = context.alertInfo?.primaryButton.action else {
            XCTFail("Couldn't find the confirmation action.")
            return
        }
        
        let deferredAction = deferFulfillment(viewModel.actionsPublisher) { $0 == .accountDeactivated }
        confirmationAction()
        try await deferredAction.fulfill()
        
        XCTAssertEqual(clientProxy.deactivateAccountPasswordEraseDataCallsCount, 2)
        XCTAssertEqual(clientProxy.deactivateAccountPasswordEraseDataReceivedArguments?.password, enteredPassword)
        XCTAssertEqual(clientProxy.deactivateAccountPasswordEraseDataReceivedArguments?.eraseData, shouldErase)
    }
}

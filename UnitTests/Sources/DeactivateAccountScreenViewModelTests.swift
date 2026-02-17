//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Foundation
import Testing

@MainActor
@Suite
struct DeactivateAccountScreenViewModelTests {
    var clientProxy: ClientProxyMock!
    var viewModel: DeactivateAccountScreenViewModelProtocol!
    
    var context: DeactivateAccountScreenViewModelType.Context {
        viewModel.context
    }
    
    init() {
        clientProxy = ClientProxyMock(.init())
        viewModel = DeactivateAccountScreenViewModel(clientProxy: clientProxy, userIndicatorController: UserIndicatorControllerMock())
    }
    
    @Test
    mutating func deactivate() async throws {
        try await validateDeactivate(erasingData: false)
    }
    
    @Test
    mutating func deactivateAndErase() async throws {
        try await validateDeactivate(erasingData: true)
    }
    
    mutating func validateDeactivate(erasingData shouldErase: Bool) async throws {
        let enteredPassword = UUID().uuidString
        
        clientProxy.deactivateAccountPasswordEraseDataClosure = { [clientProxy] password, eraseData in
            guard let clientProxy else { return .failure(.sdkError(ClientProxyMockError.generic)) }
            
            if clientProxy.deactivateAccountPasswordEraseDataCallsCount == 1 {
                #expect(password == nil, "The password shouldn't be sent first time round.")
                #expect(eraseData == shouldErase, "The erase parameter is unexpected.")
                return .failure(.sdkError(ClientProxyMockError.generic))
            } else {
                #expect(password == enteredPassword, "The password should match the user's input on the second call.")
                #expect(eraseData == shouldErase, "The erase parameter is unexpected.")
                return .success(())
            }
        }
        
        context.eraseData = shouldErase
        context.password = enteredPassword
        
        #expect(context.alertInfo == nil)
        
        let deferredState = deferFulfillment(context.observe(\.viewState.bindings.alertInfo)) { $0 != nil }
        context.send(viewAction: .deactivate)
        try await deferredState.fulfill()
        
        let confirmationAction = try #require(context.alertInfo?.primaryButton.action,
                                              "Couldn't find the confirmation action.")
        
        let deferredAction = deferFulfillment(viewModel.actionsPublisher) { $0 == .accountDeactivated }
        confirmationAction()
        try await deferredAction.fulfill()
        
        #expect(clientProxy.deactivateAccountPasswordEraseDataCallsCount == 2)
        #expect(clientProxy.deactivateAccountPasswordEraseDataReceivedArguments?.password == enteredPassword)
        #expect(clientProxy.deactivateAccountPasswordEraseDataReceivedArguments?.eraseData == shouldErase)
    }
}

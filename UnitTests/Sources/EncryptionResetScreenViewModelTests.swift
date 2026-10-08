//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
@testable import ElementX
import Testing

@MainActor
struct EncryptionResetScreenViewModelTests {
    @Test
    func resetWithConfirmationOptionsAsksForConfirmation() {
        let viewModel = makeViewModel(variant: .hasConfirmationOptions)
        
        viewModel.context.send(viewAction: .reset)
        
        #expect(viewModel.context.alertInfo != nil)
    }
    
    @Test(arguments: [EncryptionResetScreenVariant.noOptionsWithEncryptedChats, .noOptionsWithoutEncryptedChats])
    func resetWithoutOptionsSkipsConfirmation(variant: EncryptionResetScreenVariant) async throws {
        let clientProxy = ClientProxyMock(.init())
        clientProxy.resetIdentityReturnValue = .success(nil)
        let viewModel = makeViewModel(variant: variant, clientProxy: clientProxy)
        
        let deferred = deferFulfillment(viewModel.actionsPublisher) {
            if case .resetFinished = $0 {
                true
            } else {
                false
            }
        }
        viewModel.context.send(viewAction: .reset)
        try await deferred.fulfill()
        
        #expect(viewModel.context.alertInfo == nil)
        #expect(clientProxy.resetIdentityCallsCount == 1)
    }
    
    @Test
    func signOutShowsConfirmation() async throws {
        let viewModel = makeViewModel(variant: .noOptionsWithEncryptedChats)
        
        viewModel.context.send(viewAction: .signOut)
        let alertInfo = try #require(viewModel.context.alertInfo)
        
        let deferred = deferFulfillment(viewModel.actionsPublisher) {
            if case .logoutConfirmed = $0 {
                true
            } else {
                false
            }
        }
        alertInfo.primaryButton.action?()
        try await deferred.fulfill()
    }
    
    // MARK: - Helpers
    
    private func makeViewModel(variant: EncryptionResetScreenVariant, clientProxy: ClientProxyMock = ClientProxyMock(.init())) -> EncryptionResetScreenViewModel {
        EncryptionResetScreenViewModel(clientProxy: clientProxy,
                                       variant: variant,
                                       userIndicatorController: UserIndicatorControllerMock())
    }
}

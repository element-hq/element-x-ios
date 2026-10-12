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
        let viewModel = makeViewModel(mode: .hasConfirmationOptions)
        
        viewModel.context.send(viewAction: .reset)
        
        #expect(viewModel.context.alertInfo != nil)
    }
    
    @Test(arguments: [EncryptionResetScreenMode.noOptionsWithEncryptedChats, .noOptionsWithoutEncryptedChats])
    func resetWithoutOptionsSkipsConfirmation(mode: EncryptionResetScreenMode) async throws {
        let clientProxy = ClientProxyMock(.init())
        clientProxy.resetIdentityReturnValue = .success(nil)
        let viewModel = makeViewModel(mode: mode, clientProxy: clientProxy)
        
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
    func signOutSignsOutWithoutConfirmation() async throws {
        let viewModel = makeViewModel(mode: .noOptionsWithEncryptedChats)
        
        let deferred = deferFulfillment(viewModel.actionsPublisher) {
            if case .logout = $0 {
                true
            } else {
                false
            }
        }
        viewModel.context.send(viewAction: .signOut)
        try await deferred.fulfill()
        
        #expect(viewModel.context.alertInfo == nil)
    }
    
    @Test
    func modeWithConfirmationOptionsIgnoresEncryptedChats() {
        var checkedForChats = false
        let mode = EncryptionResetScreenMode(hasConfirmationOptions: true, hasEncryptedChats: {
            checkedForChats = true
            return false
        }())
        
        #expect(mode == .hasConfirmationOptions)
        #expect(!mode.isResetTheOnlyOption)
        #expect(!checkedForChats)
    }
    
    @Test
    func modeWithoutOptions() {
        let withChats = EncryptionResetScreenMode(hasConfirmationOptions: false, hasEncryptedChats: true)
        let withoutChats = EncryptionResetScreenMode(hasConfirmationOptions: false, hasEncryptedChats: false)
        
        #expect(withChats == .noOptionsWithEncryptedChats)
        #expect(withChats.isResetTheOnlyOption)
        #expect(withoutChats == .noOptionsWithoutEncryptedChats)
        #expect(withoutChats.isResetTheOnlyOption)
    }
    
    @Test
    func cancelIsForwarded() async throws {
        let viewModel = makeViewModel(mode: .hasConfirmationOptions)
        
        let deferred = deferFulfillment(viewModel.actionsPublisher) {
            if case .cancel = $0 {
                true
            } else {
                false
            }
        }
        viewModel.context.send(viewAction: .cancel)
        try await deferred.fulfill()
    }
    
    // MARK: - Helpers
    
    private func makeViewModel(mode: EncryptionResetScreenMode, clientProxy: ClientProxyMock = ClientProxyMock(.init())) -> EncryptionResetScreenViewModel {
        EncryptionResetScreenViewModel(clientProxy: clientProxy,
                                       mode: mode,
                                       userIndicatorController: UserIndicatorControllerMock())
    }
}

//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
@testable import ElementX
import Foundation
import Testing

@Suite
@MainActor
struct BlockedUsersScreenViewModelTests {
    @Test
    func initialState() async throws {
        let clientProxy = ClientProxyMock(.init(userID: RoomMemberProxyMock.mockMe.userID))
        
        let viewModel = BlockedUsersScreenViewModel(hideProfiles: true,
                                                    userSession: UserSessionMock(.init(clientProxy: clientProxy)),
                                                    userIndicatorController: ServiceLocator.shared.userIndicatorController)
        
        let deferred = deferFailure(viewModel.context.observe(\.viewState.blockedUsers), timeout: .seconds(1)) { $0.contains { $0.displayName != nil } }
        try await deferred.fulfill()
        
        #expect(!viewModel.context.viewState.blockedUsers.isEmpty)
        #expect(!clientProxy.profileForCalled)
    }
    
    @Test
    func profiles() async throws {
        let clientProxy = ClientProxyMock(.init(userID: RoomMemberProxyMock.mockMe.userID))
        
        let viewModel = BlockedUsersScreenViewModel(hideProfiles: false,
                                                    userSession: UserSessionMock(.init(clientProxy: clientProxy)),
                                                    userIndicatorController: ServiceLocator.shared.userIndicatorController)
        
        let deferred = deferFulfillment(viewModel.context.observe(\.viewState.blockedUsers)) { $0.contains { $0.displayName != nil } }
        try await deferred.fulfill()
        
        #expect(!viewModel.context.viewState.blockedUsers.isEmpty)
        #expect(clientProxy.profileForCalled)
    }
}

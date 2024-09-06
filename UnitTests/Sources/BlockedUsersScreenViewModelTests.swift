//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import XCTest

@testable import ElementX

@MainActor
class BlockedUsersScreenViewModelTests: XCTestCase {
    func testInitialState() async throws {
        let clientProxy = ClientProxyMock(.init(userID: RoomMemberProxyMock.mockMe.userID))
        
        let viewModel = BlockedUsersScreenViewModel(hideProfiles: true,
                                                    clientProxy: clientProxy,
                                                    mediaProvider: MockMediaProvider(),
                                                    userIndicatorController: ServiceLocator.shared.userIndicatorController)
        
        let deferred = deferFailure(viewModel.context.$viewState, timeout: 1) { $0.blockedUsers.contains(where: { $0.displayName != nil }) }
        try await deferred.fulfill()
        
        XCTAssertFalse(viewModel.context.viewState.blockedUsers.isEmpty)
        XCTAssertFalse(clientProxy.profileForCalled)
    }
    
    func testProfiles() async throws {
        let clientProxy = ClientProxyMock(.init(userID: RoomMemberProxyMock.mockMe.userID))
        
        let viewModel = BlockedUsersScreenViewModel(hideProfiles: false,
                                                    clientProxy: clientProxy,
                                                    mediaProvider: MockMediaProvider(),
                                                    userIndicatorController: ServiceLocator.shared.userIndicatorController)
        
        let deferred = deferFulfillment(viewModel.context.$viewState) { $0.blockedUsers.contains(where: { $0.displayName != nil }) }
        try await deferred.fulfill()
        
        XCTAssertFalse(viewModel.context.viewState.blockedUsers.isEmpty)
        XCTAssertTrue(clientProxy.profileForCalled)
    }
}

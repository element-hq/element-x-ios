//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import XCTest

@MainActor
class UserProfileScreenViewModelTests: XCTestCase {
    var viewModel: UserProfileScreenViewModel!
    var context: UserProfileScreenViewModelType.Context {
        viewModel.context
    }

    func testInitialState() async throws {
        let profile = UserProfileProxy(userID: "@alice:matrix.org", displayName: "Alice", avatarURL: .mockMXCAvatar)
        let clientProxy = ClientProxyMock(.init())
        clientProxy.profileForReturnValue = .success(profile)
        
        viewModel = UserProfileScreenViewModel(userID: profile.userID,
                                               isPresentedModally: false,
                                               userSession: UserSessionMock(.init(clientProxy: clientProxy)),
                                               userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                               analytics: ServiceLocator.shared.analytics)
        
        let waitForMemberToLoad = deferFulfillment(context.observe(\.viewState.userProfile)) { $0 != nil }
        try await waitForMemberToLoad.fulfill()
        
        XCTAssertFalse(context.viewState.isOwnUser)
        XCTAssertEqual(context.viewState.userProfile, profile)
        XCTAssertNotNil(context.viewState.permalink)
    }
    
    func testInitialStateAccountOwner() async throws {
        let profile = UserProfileProxy(userID: RoomMemberProxyMock.mockMe.userID, displayName: "Me", avatarURL: .mockMXCAvatar)
        let clientProxy = ClientProxyMock(.init())
        clientProxy.profileForReturnValue = .success(profile)
        
        viewModel = UserProfileScreenViewModel(userID: profile.userID,
                                               isPresentedModally: false,
                                               userSession: UserSessionMock(.init(clientProxy: clientProxy)),
                                               userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                               analytics: ServiceLocator.shared.analytics)
        
        let waitForMemberToLoad = deferFulfillment(context.observe(\.viewState.userProfile)) { $0 != nil }
        try await waitForMemberToLoad.fulfill()
        
        XCTAssertTrue(context.viewState.isOwnUser)
        XCTAssertEqual(context.viewState.userProfile, profile)
        XCTAssertNotNil(context.viewState.permalink)
    }
}

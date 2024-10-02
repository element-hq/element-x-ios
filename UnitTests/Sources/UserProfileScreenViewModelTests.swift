//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import XCTest

@testable import ElementX

@MainActor
class UserProfileScreenViewModelTests: XCTestCase {
    var viewModel: UserProfileScreenViewModel!
    var context: UserProfileScreenViewModelType.Context { viewModel.context }

    func testInitialState() async throws {
        let profile = UserProfileProxy(userID: "@alice:matrix.org", displayName: "Alice", avatarURL: .picturesDirectory)
        let clientProxy = ClientProxyMock(.init())
        clientProxy.profileForReturnValue = .success(profile)
        
        viewModel = UserProfileScreenViewModel(userID: profile.userID,
                                               isPresentedModally: false,
                                               clientProxy: clientProxy,
                                               mediaProvider: MockMediaProvider(),
                                               userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                               analytics: ServiceLocator.shared.analytics)
        
        let waitForMemberToLoad = deferFulfillment(context.$viewState) { $0.userProfile != nil }
        try await waitForMemberToLoad.fulfill()
        
        XCTAssertFalse(context.viewState.isOwnUser)
        XCTAssertEqual(context.viewState.userProfile, profile)
        XCTAssertNotNil(context.viewState.permalink)
    }
    
    func testInitialStateAccountOwner() async throws {
        let profile = UserProfileProxy(userID: RoomMemberProxyMock.mockMe.userID, displayName: "Me", avatarURL: .picturesDirectory)
        let clientProxy = ClientProxyMock(.init())
        clientProxy.profileForReturnValue = .success(profile)
        
        viewModel = UserProfileScreenViewModel(userID: profile.userID,
                                               isPresentedModally: false,
                                               clientProxy: clientProxy,
                                               mediaProvider: MockMediaProvider(),
                                               userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                               analytics: ServiceLocator.shared.analytics)
        
        let waitForMemberToLoad = deferFulfillment(context.$viewState) { $0.userProfile != nil }
        try await waitForMemberToLoad.fulfill()
        
        XCTAssertTrue(context.viewState.isOwnUser)
        XCTAssertEqual(context.viewState.userProfile, profile)
        XCTAssertNotNil(context.viewState.permalink)
    }
}

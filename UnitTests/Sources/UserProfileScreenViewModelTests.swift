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

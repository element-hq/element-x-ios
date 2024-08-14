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

import Combine
import XCTest

@testable import ElementX

@MainActor
class BlockedUsersScreenViewModelTests: XCTestCase {
    func testInitialState() async throws {
        let clientProxy = ClientProxyMock(.init(userID: RoomMemberProxyMock.mockMe.userID))
        
        let viewModel = BlockedUsersScreenViewModel(hideProfiles: true,
                                                    clientProxy: clientProxy,
                                                    imageProvider: MockMediaProvider(),
                                                    networkMonitor: NetworkMonitorMock.default,
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
                                                    imageProvider: MockMediaProvider(),
                                                    networkMonitor: NetworkMonitorMock.default,
                                                    userIndicatorController: ServiceLocator.shared.userIndicatorController)
        
        let deferred = deferFulfillment(viewModel.context.$viewState) { $0.blockedUsers.contains(where: { $0.displayName != nil }) }
        try await deferred.fulfill()
        
        XCTAssertFalse(viewModel.context.viewState.blockedUsers.isEmpty)
        XCTAssertTrue(clientProxy.profileForCalled)
    }
}

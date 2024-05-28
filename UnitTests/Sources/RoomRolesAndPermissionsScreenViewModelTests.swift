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
class RoomRolesAndPermissionsScreenViewModelTests: XCTestCase {
    var viewModel: RoomRolesAndPermissionsScreenViewModelProtocol!
    var roomProxy: RoomProxyMock!
    
    var context: RoomRolesAndPermissionsScreenViewModelType.Context {
        viewModel.context
    }

    func testEmptyCounters() {
        setupViewModel(members: .allMembers)
        XCTAssertEqual(context.viewState.administratorCount, 0)
        XCTAssertEqual(context.viewState.moderatorCount, 0)
    }

    func testFilledCounters() {
        setupViewModel(members: .allMembersAsAdmin)
        XCTAssertEqual(context.viewState.administratorCount, 2)
        XCTAssertEqual(context.viewState.moderatorCount, 1)
    }
    
    func testResetPermissions() async throws {
        setupViewModel(members: .allMembersAsAdmin)
        
        context.send(viewAction: .reset)
        XCTAssertNotNil(context.alertInfo)
        
        context.alertInfo?.primaryButton.action?()
        
        try await Task.sleep(for: .milliseconds(100))
        
        XCTAssertTrue(roomProxy.resetPowerLevelsCalled)
    }
    
    func testDemoteToModerator() async throws {
        setupViewModel(members: .allMembersAsAdmin)
        
        context.send(viewAction: .editOwnUserRole)
        XCTAssertNotNil(context.alertInfo)
        
        context.alertInfo?.verticalButtons?.first(where: { $0.title.localizedStandardContains("moderator") })?.action?()
        
        try await Task.sleep(for: .milliseconds(100))
        
        XCTAssertTrue(roomProxy.updatePowerLevelsForUsersCalled)
        XCTAssertEqual(roomProxy.updatePowerLevelsForUsersReceivedUpdates?.first?.powerLevel,
                       RoomMemberDetails.Role.moderator.rustPowerLevel)
    }
    
    func testDemoteToMember() async throws {
        setupViewModel(members: .allMembersAsAdmin)
        
        context.send(viewAction: .editOwnUserRole)
        XCTAssertNotNil(context.alertInfo)
        
        context.alertInfo?.verticalButtons?.first(where: { $0.title.localizedStandardContains("member") })?.action?()
        
        try await Task.sleep(for: .milliseconds(100))
        
        XCTAssertTrue(roomProxy.updatePowerLevelsForUsersCalled)
        XCTAssertEqual(roomProxy.updatePowerLevelsForUsersReceivedUpdates?.first?.powerLevel,
                       RoomMemberDetails.Role.user.rustPowerLevel)
    }
    
    private func setupViewModel(members: [RoomMemberProxyMock]) {
        roomProxy = RoomProxyMock(.init(members: members))
        viewModel = RoomRolesAndPermissionsScreenViewModel(roomProxy: roomProxy,
                                                           userIndicatorController: UserIndicatorControllerMock(),
                                                           analytics: ServiceLocator.shared.analytics)
    }
}

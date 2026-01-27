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
class RoomRolesAndPermissionsScreenViewModelTests: XCTestCase {
    var viewModel: RoomRolesAndPermissionsScreenViewModelProtocol!
    var roomProxy: JoinedRoomProxyMock!
    
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
        
        context.alertInfo?.verticalButtons?.first { $0.title.localizedStandardContains("moderator") }?.action?()
        
        try await Task.sleep(for: .milliseconds(100))
        
        XCTAssertTrue(roomProxy.updatePowerLevelsForUsersCalled)
        XCTAssertEqual(roomProxy.updatePowerLevelsForUsersReceivedUpdates?.first?.powerLevel,
                       RoomRole.moderator.powerLevelValue)
    }
    
    func testDemoteToMember() async throws {
        setupViewModel(members: .allMembersAsAdmin)
        
        context.send(viewAction: .editOwnUserRole)
        XCTAssertNotNil(context.alertInfo)
        
        context.alertInfo?.verticalButtons?.first { $0.title.localizedStandardContains("member") }?.action?()
        
        try await Task.sleep(for: .milliseconds(100))
        
        XCTAssertTrue(roomProxy.updatePowerLevelsForUsersCalled)
        XCTAssertEqual(roomProxy.updatePowerLevelsForUsersReceivedUpdates?.first?.powerLevel,
                       RoomRole.user.powerLevelValue)
    }
    
    private func setupViewModel(members: [RoomMemberProxyMock]) {
        roomProxy = JoinedRoomProxyMock(.init(members: members))
        viewModel = RoomRolesAndPermissionsScreenViewModel(roomProxy: roomProxy,
                                                           userIndicatorController: UserIndicatorControllerMock(),
                                                           analytics: ServiceLocator.shared.analytics)
    }
}

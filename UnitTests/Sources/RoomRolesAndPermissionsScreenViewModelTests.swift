//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Testing

@MainActor
@Suite
struct RoomRolesAndPermissionsScreenViewModelTests {
    @MainActor
    private struct TestSetup {
        var viewModel: RoomRolesAndPermissionsScreenViewModelProtocol
        var roomProxy: JoinedRoomProxyMock
        
        var context: RoomRolesAndPermissionsScreenViewModelType.Context {
            viewModel.context
        }
        
        init(members: [RoomMemberProxyMock]) {
            roomProxy = JoinedRoomProxyMock(.init(members: members))
            viewModel = RoomRolesAndPermissionsScreenViewModel(roomProxy: roomProxy,
                                                               userIndicatorController: UserIndicatorControllerMock(),
                                                               analytics: ServiceLocator.shared.analytics)
        }
    }

    @Test
    func emptyCounters() {
        let testSetup = TestSetup(members: .allMembers)
        #expect(testSetup.context.viewState.administratorCount == 0)
        #expect(testSetup.context.viewState.moderatorCount == 0)
    }

    @Test
    func filledCounters() {
        let testSetup = TestSetup(members: .allMembersAsAdmin)
        #expect(testSetup.context.viewState.administratorCount == 2)
        #expect(testSetup.context.viewState.moderatorCount == 1)
    }
    
    @Test
    func resetPermissions() async throws {
        let testSetup = TestSetup(members: .allMembersAsAdmin)
        
        testSetup.context.send(viewAction: .reset)
        #expect(testSetup.context.alertInfo != nil)
        
        testSetup.context.alertInfo?.primaryButton.action?()
        
        try await Task.sleep(for: .milliseconds(100))
        
        #expect(testSetup.roomProxy.resetPowerLevelsCalled)
    }
    
    @Test
    func demoteToModerator() async throws {
        let testSetup = TestSetup(members: .allMembersAsAdmin)
        
        testSetup.context.send(viewAction: .editOwnUserRole)
        #expect(testSetup.context.alertInfo != nil)
        
        testSetup.context.alertInfo?.verticalButtons?.first { $0.title.localizedStandardContains("moderator") }?.action?()
        
        try await Task.sleep(for: .milliseconds(100))
        
        #expect(testSetup.roomProxy.updatePowerLevelsForUsersCalled)
        #expect(testSetup.roomProxy.updatePowerLevelsForUsersReceivedUpdates?.first?.powerLevel == RoomRole.moderator.powerLevelValue)
    }
    
    @Test
    func demoteToMember() async throws {
        let testSetup = TestSetup(members: .allMembersAsAdmin)
        
        testSetup.context.send(viewAction: .editOwnUserRole)
        #expect(testSetup.context.alertInfo != nil)
        
        testSetup.context.alertInfo?.verticalButtons?.first { $0.title.localizedStandardContains("member") }?.action?()
        
        try await Task.sleep(for: .milliseconds(100))
        
        #expect(testSetup.roomProxy.updatePowerLevelsForUsersCalled)
        #expect(testSetup.roomProxy.updatePowerLevelsForUsersReceivedUpdates?.first?.powerLevel == RoomRole.user.powerLevelValue)
    }
}

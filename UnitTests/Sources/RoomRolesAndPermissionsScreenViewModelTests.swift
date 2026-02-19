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
    var viewModel: RoomRolesAndPermissionsScreenViewModelProtocol!
    var roomProxy: JoinedRoomProxyMock!

    var context: RoomRolesAndPermissionsScreenViewModelType.Context {
        viewModel.context
    }

    @Test
    mutating func emptyCounters() {
        setup(members: .allMembers)

        #expect(context.viewState.administratorCount == 0)
        #expect(context.viewState.moderatorCount == 0)
    }

    @Test
    mutating func filledCounters() {
        setup(members: .allMembersAsAdmin)

        #expect(context.viewState.administratorCount == 2)
        #expect(context.viewState.moderatorCount == 1)
    }
    
    @Test
    mutating func resetPermissions() async throws {
        setup(members: .allMembersAsAdmin)

        context.send(viewAction: .reset)
        #expect(context.alertInfo != nil)

        context.alertInfo?.primaryButton.action?()
        
        try await Task.sleep(for: .milliseconds(100))
        
        #expect(roomProxy.resetPowerLevelsCalled)
    }
    
    @Test
    mutating func demoteToModerator() async throws {
        setup(members: .allMembersAsAdmin)

        context.send(viewAction: .editOwnUserRole)
        #expect(context.alertInfo != nil)

        context.alertInfo?.verticalButtons?.first { $0.title.localizedStandardContains("moderator") }?.action?()

        try await Task.sleep(for: .milliseconds(100))

        #expect(roomProxy.updatePowerLevelsForUsersCalled)
        #expect(roomProxy.updatePowerLevelsForUsersReceivedUpdates?.first?.powerLevel == RoomRole.moderator.powerLevelValue)
    }
    
    @Test
    mutating func demoteToMember() async throws {
        setup(members: .allMembersAsAdmin)

        context.send(viewAction: .editOwnUserRole)
        #expect(context.alertInfo != nil)

        context.alertInfo?.verticalButtons?.first { $0.title.localizedStandardContains("member") }?.action?()

        try await Task.sleep(for: .milliseconds(100))

        #expect(roomProxy.updatePowerLevelsForUsersCalled)
        #expect(roomProxy.updatePowerLevelsForUsersReceivedUpdates?.first?.powerLevel == RoomRole.user.powerLevelValue)
    }

    // MARK: - Helpers

    private mutating func setup(members: [RoomMemberProxyMock]) {
        roomProxy = JoinedRoomProxyMock(.init(members: members))
        viewModel = RoomRolesAndPermissionsScreenViewModel(roomProxy: roomProxy,
                                                           userIndicatorController: UserIndicatorControllerMock(),
                                                           analytics: ServiceLocator.shared.analytics)
    }
}

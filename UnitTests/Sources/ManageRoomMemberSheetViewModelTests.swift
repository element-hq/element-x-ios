//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Testing

@MainActor
struct ManageRoomMemberSheetViewModelTests {
    private var viewModel: ManageRoomMemberSheetViewModel!
    private var context: ManageRoomMemberSheetViewModel.Context! {
        viewModel.context
    }
    
    @Test
    mutating func kick() async throws {
        let testReason = "Kick Test"
        let roomProxy = JoinedRoomProxyMock(.init(members: [RoomMemberProxyMock.mockAdmin, RoomMemberProxyMock.mockAlice]))
        var kickCalled = false
        roomProxy.kickUserReasonClosure = { userID, reason in
            kickCalled = true
            #expect(userID == RoomMemberProxyMock.mockAlice.userID)
            #expect(reason == testReason)
            return .success(())
        }
        
        viewModel = ManageRoomMemberSheetViewModel(memberDetails: .memberDetails(roomMember: .init(withProxy: RoomMemberProxyMock.mockAlice)),
                                                   permissions: .init(canKick: true, canBan: true, ownPowerLevel: RoomMemberProxyMock.mockAdmin.powerLevel),
                                                   roomProxy: roomProxy,
                                                   userIndicatorController: UserIndicatorControllerMock(),
                                                   analyticsService: AnalyticsServiceMock(.init()),
                                                   mediaProvider: MediaProviderMock(.init()))
        
        let deferred = deferFulfillment(context.observe(\.viewState.bindings.alertInfo)) { $0 != nil }
        let deferredAction = deferFulfillment(viewModel.actions) { action in
            action == .dismiss(shouldShowDetails: false)
        }
        context.send(viewAction: .kick)
        try await deferred.fulfill()
        
        context.alertInfo?.textFields?[0].text.wrappedValue = testReason
        context.alertInfo?.secondaryButton?.action?()
        try await deferredAction.fulfill()
        #expect(kickCalled)
    }
    
    @Test
    mutating func ban() async throws {
        let testReason = "Ban Test"
        let roomProxy = JoinedRoomProxyMock(.init(members: [RoomMemberProxyMock.mockAdmin, RoomMemberProxyMock.mockAlice]))
        var banCalled = false
        roomProxy.banUserReasonClosure = { userID, reason in
            banCalled = true
            #expect(userID == RoomMemberProxyMock.mockAlice.userID)
            #expect(reason == testReason)
            return .success(())
        }
        
        viewModel = ManageRoomMemberSheetViewModel(memberDetails: .memberDetails(roomMember: .init(withProxy: RoomMemberProxyMock.mockAlice)),
                                                   permissions: .init(canKick: true, canBan: true, ownPowerLevel: RoomMemberProxyMock.mockAdmin.powerLevel),
                                                   roomProxy: roomProxy,
                                                   userIndicatorController: UserIndicatorControllerMock(),
                                                   analyticsService: AnalyticsServiceMock(.init()),
                                                   mediaProvider: MediaProviderMock(.init()))
        
        let deferred = deferFulfillment(context.observe(\.viewState.bindings.alertInfo)) { $0 != nil }
        context.send(viewAction: .ban)
        try await deferred.fulfill()
        
        let deferredAction = deferFulfillment(viewModel.actions) { action in
            action == .dismiss(shouldShowDetails: false)
        }
        context.alertInfo?.textFields?[0].text.wrappedValue = testReason
        context.alertInfo?.secondaryButton?.action?()
        try await deferredAction.fulfill()
        #expect(banCalled)
    }
    
    @Test
    mutating func displayDetails() async throws {
        let roomProxy = JoinedRoomProxyMock(.init(members: [RoomMemberProxyMock.mockAdmin, RoomMemberProxyMock.mockAlice]))
        viewModel = ManageRoomMemberSheetViewModel(memberDetails: .memberDetails(roomMember: .init(withProxy: RoomMemberProxyMock.mockAlice)),
                                                   permissions: .init(canKick: true, canBan: true, ownPowerLevel: RoomMemberProxyMock.mockAdmin.powerLevel),
                                                   roomProxy: roomProxy,
                                                   userIndicatorController: UserIndicatorControllerMock(),
                                                   analyticsService: AnalyticsServiceMock(.init()),
                                                   mediaProvider: MediaProviderMock(.init()))
        
        let deferredAction = deferFulfillment(viewModel.actions) { action in
            action == .dismiss(shouldShowDetails: true)
        }
        context.send(viewAction: .displayDetails)
        try await deferredAction.fulfill()
        #expect(context.alertInfo == nil)
    }
    
    @Test
    mutating func displayAvatar() async throws {
        let member = RoomMemberDetails(withProxy: RoomMemberProxyMock.mockDan)
        viewModel = ManageRoomMemberSheetViewModel(memberDetails: .memberDetails(roomMember: member),
                                                   permissions: .init(canKick: true, canBan: true, ownPowerLevel: RoomMemberProxyMock.mockAdmin.powerLevel),
                                                   roomProxy: JoinedRoomProxyMock(.init()),
                                                   userIndicatorController: UserIndicatorControllerMock(),
                                                   analyticsService: AnalyticsServiceMock(.init()),
                                                   mediaProvider: MediaProviderMock(.init()))
        
        let avatarURL = try #require(member.avatarURL)
        let deferred = deferFulfillment(context.observe(\.viewState.bindings.mediaPreviewItem)) { $0 != nil }
        context.send(viewAction: .displayAvatar(avatarURL))
        try await deferred.fulfill()
        
        #expect(context.mediaPreviewItem?.previewItemTitle == member.name)
    }

    @Test
    mutating func roleVisibility() {
        // An admin looking at a moderator can edit their role.
        setupForRoles(member: RoomMemberProxyMock.mockModerator, canEditRoles: true)
        #expect(context.viewState.isRoleVisible)
        #expect(context.viewState.isRoleEditable)
        #expect(context.viewState.availableRoles == [.administrator, .moderator, .user])
        #expect(context.selectedRole == .moderator)

        // An admin looking at another admin sees the role but can't edit it.
        setupForRoles(member: RoomMemberProxyMock.mockAdmin, canEditRoles: true)
        #expect(context.viewState.isRoleVisible)
        #expect(!context.viewState.isRoleEditable)

        // An admin looking at a regular member can promote them.
        setupForRoles(member: RoomMemberProxyMock.mockAlice, canEditRoles: true)
        #expect(context.viewState.isRoleVisible)
        #expect(context.viewState.isRoleEditable)

        // Without permission to edit power levels a regular member's role is hidden…
        setupForRoles(member: RoomMemberProxyMock.mockAlice, canEditRoles: false)
        #expect(!context.viewState.isRoleVisible)

        // …but a non-default role is always shown.
        setupForRoles(member: RoomMemberProxyMock.mockModerator, canEditRoles: false)
        #expect(context.viewState.isRoleVisible)
        #expect(!context.viewState.isRoleEditable)
    }

    @Test
    mutating func updateRole() async throws {
        // Demoting a moderator to a member doesn't need any confirmation.
        let roomProxy = setupForRoles(member: RoomMemberProxyMock.mockModerator, canEditRoles: true)

        let deferredAction = deferFulfillment(viewModel.actions) { action in
            action == .dismiss(shouldShowDetails: false)
        }
        context.send(viewAction: .updateRole(.user))
        try await deferredAction.fulfill()

        #expect(context.alertInfo == nil)
        #expect(roomProxy.updatePowerLevelsForUsersReceivedUpdates?.count == 1)
        #expect(roomProxy.updatePowerLevelsForUsersReceivedUpdates?.contains { $0.userID == RoomMemberProxyMock.mockModerator.userID && $0.powerLevel == 0 } == true)
    }

    @Test
    mutating func promoteToAdminWarning() async throws {
        // Promoting someone to your own power level shows a warning first.
        let roomProxy = setupForRoles(member: RoomMemberProxyMock.mockAlice, canEditRoles: true)

        let deferred = deferFulfillment(context.observe(\.viewState.bindings.alertInfo)) { $0 != nil }
        context.send(viewAction: .updateRole(.administrator))
        try await deferred.fulfill()

        #expect(!roomProxy.updatePowerLevelsForUsersCalled)

        let deferredAction = deferFulfillment(viewModel.actions) { action in
            action == .dismiss(shouldShowDetails: false)
        }
        context.alertInfo?.primaryButton.action?()
        try await deferredAction.fulfill()

        #expect(roomProxy.updatePowerLevelsForUsersReceivedUpdates?.contains { $0.userID == RoomMemberProxyMock.mockAlice.userID && $0.powerLevel == 100 } == true)
    }

    @Test
    mutating func cancelledRoleChangeRevertsSelection() async throws {
        let roomProxy = setupForRoles(member: RoomMemberProxyMock.mockAlice, canEditRoles: true)

        let deferred = deferFulfillment(context.observe(\.viewState.bindings.alertInfo)) { $0 != nil }
        context.selectedRole = .administrator
        context.send(viewAction: .updateRole(.administrator))
        try await deferred.fulfill()

        context.alertInfo?.secondaryButton?.action?()

        #expect(context.selectedRole == .user)
        #expect(!roomProxy.updatePowerLevelsForUsersCalled)
    }

    @Test
    mutating func demoteOwnUser() async throws {
        // Own user goes through the Change my role dialog, offering only demotions.
        let roomProxy = setupForRoles(member: RoomMemberProxyMock.mockMeAdmin, canEditRoles: true)
        #expect(context.viewState.isOwnUser)
        #expect(context.viewState.isRoleVisible)
        #expect(context.viewState.isRoleEditable)
        #expect(!context.viewState.isKickDisabled)

        let deferred = deferFulfillment(context.observe(\.viewState.bindings.alertInfo)) { $0 != nil }
        context.send(viewAction: .changeOwnRole)
        try await deferred.fulfill()

        let demotionButtons = try #require(context.alertInfo?.verticalButtons)
        #expect(demotionButtons.count == 2) // Moderator and member for an admin.

        let deferredAction = deferFulfillment(viewModel.actions) { action in
            action == .dismiss(shouldShowDetails: false)
        }
        demotionButtons.last?.action?()
        try await deferredAction.fulfill()

        #expect(roomProxy.updatePowerLevelsForUsersReceivedUpdates?.contains { $0.userID == RoomMemberProxyMock.mockMeAdmin.userID && $0.powerLevel == 0 } == true)
    }

    @Test
    mutating func ownRegularUserHasNoRoleRow() {
        // A regular member can't demote themselves any further, so no role row.
        setupForRoles(member: RoomMemberProxyMock.mockMe, canEditRoles: true)
        #expect(context.viewState.isOwnUser)
        #expect(!context.viewState.isRoleVisible)
    }

    @discardableResult
    private mutating func setupForRoles(member: RoomMemberProxyMock, canEditRoles: Bool) -> JoinedRoomProxyMock {
        let roomProxy = JoinedRoomProxyMock(.init(members: [RoomMemberProxyMock.mockMeAdmin, member]))
        viewModel = ManageRoomMemberSheetViewModel(memberDetails: .memberDetails(roomMember: .init(withProxy: member)),
                                                   permissions: .init(canKick: true,
                                                                      canBan: true,
                                                                      canEditRoles: canEditRoles,
                                                                      ownPowerLevel: RoomMemberProxyMock.mockMeAdmin.powerLevel),
                                                   roomProxy: roomProxy,
                                                   userIndicatorController: UserIndicatorControllerMock(),
                                                   analyticsService: AnalyticsServiceMock(.init()),
                                                   mediaProvider: MediaProviderMock(.init()))
        return roomProxy
    }
}

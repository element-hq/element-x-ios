//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
@testable import ElementX
import Testing

@Suite
@MainActor
struct RoomMembersListScreenViewModelTests {
    var viewModel: RoomMembersListScreenViewModel!
    var roomProxy: JoinedRoomProxyMock!
    var context: RoomMembersListScreenViewModel.Context {
        viewModel.context
    }

    @Test
    mutating func joinedMembers() async throws {
        setup(members: [.mockAlice, .mockBob])

        let deferred = deferFulfillment(context.$viewState) { state in
            state.visibleJoinedMembers.count == 2
        }
        try await deferred.fulfill()

        #expect(viewModel.state.joinedMembersCount == 2)
        #expect(viewModel.state.visibleJoinedMembers.count == 2)
    }

    @Test
    mutating func sortingMembers() async throws {
        setup(members: [.mockModerator, .mockDan, .mockAlice, .mockAdmin])

        let deferred = deferFulfillment(context.$viewState) { state in
            state.visibleJoinedMembers.count == 4
        }
        try await deferred.fulfill()

        let sortedMembers: [RoomMemberListScreenEntry] = [
            .init(member: .init(withProxy: RoomMemberProxyMock.mockAdmin),
                  verificationState: .notVerified),
            .init(member: .init(withProxy: RoomMemberProxyMock.mockModerator),
                  verificationState: .notVerified),
            .init(member: .init(withProxy: RoomMemberProxyMock.mockAlice),
                  verificationState: .notVerified),
            .init(member: .init(withProxy: RoomMemberProxyMock.mockDan),
                  verificationState: .notVerified)
        ]

        #expect(viewModel.state.visibleJoinedMembers == sortedMembers)
    }

    @Test
    mutating func search() async throws {
        setup(members: [.mockAlice, .mockBob])

        let deferred = deferFulfillment(context.$viewState) { state in
            state.visibleJoinedMembers.count == 1
        }
        context.searchQuery = "alice"
        try await deferred.fulfill()

        #expect(viewModel.state.joinedMembersCount == 2)
        #expect(viewModel.state.visibleJoinedMembers.count == 1)
    }

    @Test
    mutating func emptySearch() async throws {
        setup(members: [.mockAlice, .mockBob])

        context.searchQuery = "WWW"
        let deferred = deferFulfillment(context.$viewState) { state in
            state.joinedMembersCount == 2
        }
        try await deferred.fulfill()

        #expect(viewModel.state.joinedMembersCount == 2)
        #expect(viewModel.state.visibleJoinedMembers.count == 0)
    }

    @Test
    mutating func joinedAndInvitedMembers() async throws {
        setup(members: [.mockInvited, .mockBob])

        let deferred = deferFulfillment(context.$viewState) { state in
            state.visibleInvitedMembers.count == 1
        }
        try await deferred.fulfill()

        #expect(viewModel.state.joinedMembersCount == 1)
        #expect(viewModel.state.visibleInvitedMembers.count == 1)
        #expect(viewModel.state.visibleJoinedMembers.count == 1)
    }

    @Test
    mutating func invitedMembers() async throws {
        setup(members: [.mockInvited])

        let deferred = deferFulfillment(context.$viewState) { state in
            state.visibleInvitedMembers.count == 1
        }
        try await deferred.fulfill()

        #expect(viewModel.state.joinedMembersCount == 0)
        #expect(viewModel.state.visibleInvitedMembers.count == 1)
        #expect(viewModel.state.visibleJoinedMembers.count == 0)
    }

    @Test
    mutating func searchInvitedMembers() async throws {
        setup(members: [.mockInvited])

        context.searchQuery = "invited"
        let deferred = deferFulfillment(context.$viewState) { state in
            state.visibleInvitedMembers.count == 1
        }
        try await deferred.fulfill()

        #expect(viewModel.state.joinedMembersCount == 0)
        #expect(viewModel.state.visibleInvitedMembers.count == 1)
        #expect(viewModel.state.visibleJoinedMembers.count == 0)
    }

    @Test
    mutating func selectUserAsUser() async throws {
        setup(members: .allMembers)

        var deferred = deferFulfillment(context.$viewState) { !$0.visibleInvitedMembers.isEmpty }
        try await deferred.fulfill()

        deferred = deferFulfillment(context.$viewState) { $0.bindings.manageMemeberViewModel != nil }
        guard let user = viewModel.state.visibleJoinedMembers.first(where: { $0.member.role == .user && $0.member.id != RoomMemberProxyMock.mockMe.userID })?.member else {
            Issue.record("Expected to find a regular user.")
            return
        }

        context.send(viewAction: .selectMember(user))
        try await deferred.fulfill()

        #expect(context.manageMemeberViewModel != nil)
        #expect(context.manageMemeberViewModel?.state.memberDetails.id == user.id)
        #expect(context.manageMemeberViewModel?.state.permissions.canKick == false)
        #expect(context.manageMemeberViewModel?.state.permissions.canBan == false)
    }

    @Test
    mutating func selectUserAsAdmin() async throws {
        setup(members: .allMembersAsAdmin)

        var deferred = deferFulfillment(context.$viewState) { !$0.visibleInvitedMembers.isEmpty && $0.canKickUsers && $0.canBanUsers }
        try await deferred.fulfill()

        #expect(context.manageMemeberViewModel == nil)

        deferred = deferFulfillment(context.$viewState) { $0.bindings.manageMemeberViewModel != nil }
        guard let user = viewModel.state.visibleJoinedMembers.first(where: { $0.member.role == .user && $0.member.id != RoomMemberProxyMock.mockMe.userID })?.member else {
            Issue.record("Expected to find a regular user.")
            return
        }

        context.send(viewAction: .selectMember(user))
        try await deferred.fulfill()

        #expect(context.manageMemeberViewModel?.state.memberDetails.id == user.id)
        #expect(context.manageMemeberViewModel?.state.permissions.canKick == true)
        #expect(context.manageMemeberViewModel?.state.permissions.canBan == true)
        #expect(context.manageMemeberViewModel?.state.isKickDisabled == false)
        #expect(context.manageMemeberViewModel?.state.isBanUnbanDisabled == false)
        #expect(context.manageMemeberViewModel?.state.isMemberBanned == false)
    }

    @Test
    mutating func selectModeratorAsAdmin() async throws {
        setup(members: .allMembersAsAdmin)

        var deferred = deferFulfillment(context.$viewState) { !$0.visibleInvitedMembers.isEmpty && $0.canKickUsers && $0.canBanUsers }
        try await deferred.fulfill()

        #expect(context.manageMemeberViewModel == nil)

        deferred = deferFulfillment(context.$viewState) { $0.bindings.manageMemeberViewModel != nil }
        guard let moderator = viewModel.state.visibleJoinedMembers.first(where: { $0.member.role == .moderator })?.member else {
            Issue.record("Expected to find a moderator.")
            return
        }

        context.send(viewAction: .selectMember(moderator))
        try await deferred.fulfill()

        #expect(context.manageMemeberViewModel?.state.memberDetails.id == moderator.id)
        #expect(context.manageMemeberViewModel?.state.permissions.canKick == true)
        #expect(context.manageMemeberViewModel?.state.permissions.canBan == true)
        #expect(context.manageMemeberViewModel?.state.isMemberBanned == false)
        #expect(context.manageMemeberViewModel?.state.isKickDisabled == false)
        #expect(context.manageMemeberViewModel?.state.isBanUnbanDisabled == false)
    }

    @Test
    mutating func selectAdminAsAdmin() async throws {
        setup(members: .allMembersAsAdmin)

        var deferred = deferFulfillment(context.$viewState) { !$0.visibleInvitedMembers.isEmpty && $0.canKickUsers && $0.canBanUsers }
        try await deferred.fulfill()

        deferred = deferFulfillment(context.$viewState) { $0.bindings.manageMemeberViewModel != nil }
        guard let admin = viewModel.state.visibleJoinedMembers.first(where: { $0.member.role.isAdminOrHigher && $0.member.id != RoomMemberProxyMock.mockMe.userID })?.member else {
            Issue.record("Expected to find another admin.")
            return
        }

        context.send(viewAction: .selectMember(admin))
        try await deferred.fulfill()

        #expect(context.manageMemeberViewModel?.state.memberDetails.id == admin.id)
        #expect(context.manageMemeberViewModel?.state.permissions.canKick == true)
        #expect(context.manageMemeberViewModel?.state.permissions.canBan == true)
        #expect(context.manageMemeberViewModel?.state.isKickDisabled == true)
        #expect(context.manageMemeberViewModel?.state.isBanUnbanDisabled == true)
        #expect(context.manageMemeberViewModel?.state.isMemberBanned == false)
    }

    @Test
    mutating func selectOwnMemberAsAdmin() async throws {
        setup(members: .allMembersAsAdmin)

        let deferred = deferFulfillment(context.$viewState) { !$0.visibleInvitedMembers.isEmpty }
        try await deferred.fulfill()

        let memberDetailsAction = deferFulfillment(viewModel.actions) { $0.isSelectMember }
        guard let ownMember = viewModel.state.visibleJoinedMembers.first(where: { $0.member.id == RoomMemberProxyMock.mockMe.userID })?.member else {
            Issue.record("Expected to find own user admin.")
            return
        }

        context.send(viewAction: .selectMember(ownMember))
        try await memberDetailsAction.fulfill()

        #expect(context.manageMemeberViewModel == nil)
    }

    @Test
    mutating func selectBannedMember() async throws {
        setup(members: .allMembersAsAdmin + RoomMemberProxyMock.mockBanned)

        var deferred = deferFulfillment(context.$viewState) { !$0.visibleInvitedMembers.isEmpty && $0.canKickUsers && $0.canBanUsers }
        try await deferred.fulfill()

        #expect(context.alertInfo == nil)

        deferred = deferFulfillment(context.$viewState) { $0.bindings.manageMemeberViewModel != nil }
        guard let bannedMember = viewModel.state.visibleBannedMembers.first?.member else {
            Issue.record("Expected to find a banned user.")
            return
        }

        context.send(viewAction: .selectMember(bannedMember))
        try await deferred.fulfill()

        #expect(context.manageMemeberViewModel?.state.memberDetails.id == bannedMember.id)
        #expect(context.manageMemeberViewModel?.state.permissions.canKick == true)
        #expect(context.manageMemeberViewModel?.state.permissions.canBan == true)
        #expect(context.manageMemeberViewModel?.state.isKickDisabled == true)
        #expect(context.manageMemeberViewModel?.state.isBanUnbanDisabled == false)
        #expect(context.manageMemeberViewModel?.state.isMemberBanned == true)
    }

    @Test
    mutating func switchesToMembersModeWhenThereAreNoBannedMembers() async throws {
        roomProxy = JoinedRoomProxyMock(.init(name: "test"))

        let subject = CurrentValueSubject<[RoomMemberProxyProtocol], Never>([RoomMemberProxyMock].allMembersAsAdmin + RoomMemberProxyMock.mockBanned)
        roomProxy.membersPublisher = subject.asCurrentValuePublisher()

        viewModel = RoomMembersListScreenViewModel(userSession: UserSessionMock(.init()),
                                                   roomProxy: roomProxy,
                                                   userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                                   analytics: ServiceLocator.shared.analytics)

        let context = viewModel.context

        var deferred = deferFulfillment(context.$viewState) { $0.visibleBannedMembers.count == 4 && $0.bindings.mode == .banned }
        context.mode = .banned
        try await deferred.fulfill()

        deferred = deferFulfillment(context.$viewState) { $0.visibleBannedMembers.count == 0 && $0.bindings.mode == .members }
        subject.value = [RoomMemberProxyMock].allMembersAsAdmin
        try await deferred.fulfill()
    }

    // MARK: - Helpers

    private mutating func setup(members: [RoomMemberProxyMock]) {
        roomProxy = JoinedRoomProxyMock(.init(name: "test", members: members))
        viewModel = RoomMembersListScreenViewModel(userSession: UserSessionMock(.init()),
                                                   roomProxy: roomProxy,
                                                   userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                                   analytics: ServiceLocator.shared.analytics)
    }
}

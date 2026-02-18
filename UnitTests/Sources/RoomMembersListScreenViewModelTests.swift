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

@MainActor
@Suite
struct RoomMembersListScreenViewModelTests {
    @MainActor
    private struct TestSetup {
        var viewModel: RoomMembersListScreenViewModel
        var roomProxy: JoinedRoomProxyMock
        
        var context: RoomMembersListScreenViewModel.Context {
            viewModel.context
        }
        
        init(with members: [RoomMemberProxyMock]) {
            roomProxy = JoinedRoomProxyMock(.init(name: "test", members: members))
            viewModel = RoomMembersListScreenViewModel(userSession: UserSessionMock(.init()),
                                                       roomProxy: roomProxy,
                                                       userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                                       analytics: ServiceLocator.shared.analytics)
        }
    }
    
    @Test
    func joinedMembers() async throws {
        let testSetup = TestSetup(with: [.mockAlice, .mockBob])
        
        let deferred = deferFulfillment(testSetup.context.$viewState) { state in
            state.visibleJoinedMembers.count == 2
        }
        
        try await deferred.fulfill()
        
        #expect(testSetup.viewModel.state.joinedMembersCount == 2)
        #expect(testSetup.viewModel.state.visibleJoinedMembers.count == 2)
    }
    
    @Test
    func sortingMembers() async throws {
        let testSetup = TestSetup(with: [.mockModerator, .mockDan, .mockAlice, .mockAdmin])
        
        let deferred = deferFulfillment(testSetup.context.$viewState) { state in
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
        
        #expect(testSetup.viewModel.state.visibleJoinedMembers == sortedMembers)
    }
    
    @Test
    func search() async throws {
        let testSetup = TestSetup(with: [.mockAlice, .mockBob])
        
        let deferred = deferFulfillment(testSetup.context.$viewState) { state in
            state.visibleJoinedMembers.count == 1
        }
        
        testSetup.context.searchQuery = "alice"
        
        try await deferred.fulfill()
        
        #expect(testSetup.viewModel.state.joinedMembersCount == 2)
        #expect(testSetup.viewModel.state.visibleJoinedMembers.count == 1)
    }
    
    @Test
    func emptySearch() async throws {
        let testSetup = TestSetup(with: [.mockAlice, .mockBob])
        testSetup.context.searchQuery = "WWW"
        
        let deferred = deferFulfillment(testSetup.context.$viewState) { state in
            state.joinedMembersCount == 2
        }
        
        try await deferred.fulfill()
        
        #expect(testSetup.viewModel.state.joinedMembersCount == 2)
        #expect(testSetup.viewModel.state.visibleJoinedMembers.count == 0)
    }
    
    @Test
    func joinedAndInvitedMembers() async throws {
        let testSetup = TestSetup(with: [.mockInvited, .mockBob])
        
        let deferred = deferFulfillment(testSetup.context.$viewState) { state in
            state.visibleInvitedMembers.count == 1
        }
        
        try await deferred.fulfill()
        
        #expect(testSetup.viewModel.state.joinedMembersCount == 1)
        #expect(testSetup.viewModel.state.visibleInvitedMembers.count == 1)
        #expect(testSetup.viewModel.state.visibleJoinedMembers.count == 1)
    }
    
    @Test
    func invitedMembers() async throws {
        let testSetup = TestSetup(with: [.mockInvited])
        
        let deferred = deferFulfillment(testSetup.context.$viewState) { state in
            state.visibleInvitedMembers.count == 1
        }
        
        try await deferred.fulfill()
        
        #expect(testSetup.viewModel.state.joinedMembersCount == 0)
        #expect(testSetup.viewModel.state.visibleInvitedMembers.count == 1)
        #expect(testSetup.viewModel.state.visibleJoinedMembers.count == 0)
    }
    
    @Test
    func searchInvitedMembers() async throws {
        let testSetup = TestSetup(with: [.mockInvited])
        
        testSetup.context.searchQuery = "invited"
        
        let deferred = deferFulfillment(testSetup.context.$viewState) { state in
            state.visibleInvitedMembers.count == 1
        }
        
        try await deferred.fulfill()
        
        #expect(testSetup.viewModel.state.joinedMembersCount == 0)
        #expect(testSetup.viewModel.state.visibleInvitedMembers.count == 1)
        #expect(testSetup.viewModel.state.visibleJoinedMembers.count == 0)
    }
    
    @Test
    func selectUserAsUser() async throws {
        // Given the room list viewed as a regular user.
        let testSetup = TestSetup(with: .allMembers)
        var deferred = deferFulfillment(testSetup.context.$viewState) { !$0.visibleInvitedMembers.isEmpty }
        try await deferred.fulfill()
        
        // When tapping on another user in the list.
        deferred = deferFulfillment(testSetup.context.$viewState) { $0.bindings.manageMemeberViewModel != nil }
        guard let user = testSetup.viewModel.state.visibleJoinedMembers.first(where: { $0.member.role == .user && $0.member.id != RoomMemberProxyMock.mockMe.userID })?.member else {
            Issue.record("Expected to find a regular user.")
            return
        }
        testSetup.context.send(viewAction: .selectMember(user))
        
        // Then the member's details should be shown.
        try await deferred.fulfill()
        #expect(testSetup.context.manageMemeberViewModel != nil)
        #expect(testSetup.context.manageMemeberViewModel?.state.memberDetails.id == user.id)
        #expect(testSetup.context.manageMemeberViewModel?.state.permissions.canKick == false)
        #expect(testSetup.context.manageMemeberViewModel?.state.permissions.canBan == false)
    }
    
    @Test
    func selectUserAsAdmin() async throws {
        // Given the room list viewed as an admin.
        let testSetup = TestSetup(with: .allMembersAsAdmin)
        var deferred = deferFulfillment(testSetup.context.$viewState) { !$0.visibleInvitedMembers.isEmpty && $0.canKickUsers && $0.canBanUsers }
        try await deferred.fulfill()
        #expect(testSetup.context.manageMemeberViewModel == nil)
        
        // When tapping on a user in the list.
        deferred = deferFulfillment(testSetup.context.$viewState) { $0.bindings.manageMemeberViewModel != nil }
        guard let user = testSetup.viewModel.state.visibleJoinedMembers.first(where: { $0.member.role == .user && $0.member.id != RoomMemberProxyMock.mockMe.userID })?.member else {
            Issue.record("Expected to find a regular user.")
            return
        }
        testSetup.context.send(viewAction: .selectMember(user))
        try await deferred.fulfill()
        
        // Then member management should be shown for that user.
        #expect(testSetup.context.manageMemeberViewModel?.state.memberDetails.id == user.id)
        #expect(testSetup.context.manageMemeberViewModel?.state.permissions.canKick == true)
        #expect(testSetup.context.manageMemeberViewModel?.state.permissions.canBan == true)
        #expect(testSetup.context.manageMemeberViewModel?.state.isKickDisabled == false)
        #expect(testSetup.context.manageMemeberViewModel?.state.isBanUnbanDisabled == false)
        #expect(testSetup.context.manageMemeberViewModel?.state.isMemberBanned == false)
    }
    
    @Test
    func selectModeratorAsAdmin() async throws {
        // Given the room list viewed as an admin.
        let testSetup = TestSetup(with: .allMembersAsAdmin)
        var deferred = deferFulfillment(testSetup.context.$viewState) { !$0.visibleInvitedMembers.isEmpty && $0.canKickUsers && $0.canBanUsers }
        try await deferred.fulfill()
        #expect(testSetup.context.manageMemeberViewModel == nil)
        
        // When tapping on a moderator in the list.
        deferred = deferFulfillment(testSetup.context.$viewState) { $0.bindings.manageMemeberViewModel != nil }
        guard let moderator = testSetup.viewModel.state.visibleJoinedMembers.first(where: { $0.member.role == .moderator })?.member else {
            Issue.record("Expected to find a moderator.")
            return
        }
        testSetup.context.send(viewAction: .selectMember(moderator))
        try await deferred.fulfill()
        
        // Then member management should be shown for the moderator.
        #expect(testSetup.context.manageMemeberViewModel?.state.memberDetails.id == moderator.id)
        #expect(testSetup.context.manageMemeberViewModel?.state.permissions.canKick == true)
        #expect(testSetup.context.manageMemeberViewModel?.state.permissions.canBan == true)
        #expect(testSetup.context.manageMemeberViewModel?.state.isMemberBanned == false)
        #expect(testSetup.context.manageMemeberViewModel?.state.isKickDisabled == false)
        #expect(testSetup.context.manageMemeberViewModel?.state.isBanUnbanDisabled == false)
    }
    
    @Test
    func selectAdminAsAdmin() async throws {
        // Given the room list viewed as an admin.
        let testSetup = TestSetup(with: .allMembersAsAdmin)
        var deferred = deferFulfillment(testSetup.context.$viewState) { !$0.visibleInvitedMembers.isEmpty && $0.canKickUsers && $0.canBanUsers }
        try await deferred.fulfill()
        
        // When tapping on another administrator in the list.
        deferred = deferFulfillment(testSetup.context.$viewState) { $0.bindings.manageMemeberViewModel != nil }
        guard let admin = testSetup.viewModel.state.visibleJoinedMembers.first(where: { $0.member.role.isAdminOrHigher && $0.member.id != RoomMemberProxyMock.mockMe.userID })?.member else {
            Issue.record("Expected to find another admin.")
            return
        }
        testSetup.context.send(viewAction: .selectMember(admin))
        
        // Then the administrator's details should be shown.
        try await deferred.fulfill()
        #expect(testSetup.context.manageMemeberViewModel?.state.memberDetails.id == admin.id)
        #expect(testSetup.context.manageMemeberViewModel?.state.permissions.canKick == true)
        #expect(testSetup.context.manageMemeberViewModel?.state.permissions.canBan == true)
        #expect(testSetup.context.manageMemeberViewModel?.state.isKickDisabled == true)
        #expect(testSetup.context.manageMemeberViewModel?.state.isBanUnbanDisabled == true)
        #expect(testSetup.context.manageMemeberViewModel?.state.isMemberBanned == false)
    }
    
    @Test
    func selectOwnMemberAsAdmin() async throws {
        // Given the room list viewed as an admin.
        let testSetup = TestSetup(with: .allMembersAsAdmin)
        let deferred = deferFulfillment(testSetup.context.$viewState) { !$0.visibleInvitedMembers.isEmpty }
        try await deferred.fulfill()
        
        // When tapping on yourself in the list.
        let memberDetailsAction = deferFulfillment(testSetup.viewModel.actions) { $0.isSelectMember }
        guard let ownMember = testSetup.viewModel.state.visibleJoinedMembers.first(where: { $0.member.id == RoomMemberProxyMock.mockMe.userID })?.member else {
            Issue.record("Expected to find own user admin.")
            return
        }
        testSetup.context.send(viewAction: .selectMember(ownMember))
        
        // Then your member's details should be shown.
        try await memberDetailsAction.fulfill()
        #expect(testSetup.context.manageMemeberViewModel == nil)
    }
    
    @Test
    func selectBannedMember() async throws {
        // Given the room list viewed as an admin.
        let testSetup = TestSetup(with: .allMembersAsAdmin + RoomMemberProxyMock.mockBanned)
        var deferred = deferFulfillment(testSetup.context.$viewState) { !$0.visibleInvitedMembers.isEmpty && $0.canKickUsers && $0.canBanUsers }
        try await deferred.fulfill()
        #expect(testSetup.context.alertInfo == nil)
        
        // When tapping on a banned member in the list.
        deferred = deferFulfillment(testSetup.context.$viewState) { $0.bindings.manageMemeberViewModel != nil }
        guard let bannedMember = testSetup.viewModel.state.visibleBannedMembers.first?.member else {
            Issue.record("Expected to find a banned user.")
            return
        }
        testSetup.context.send(viewAction: .selectMember(bannedMember))
        
        // Then an alert should be shown to unban the user.
        try await deferred.fulfill()
        #expect(testSetup.context.manageMemeberViewModel?.state.memberDetails.id == bannedMember.id)
        #expect(testSetup.context.manageMemeberViewModel?.state.permissions.canKick == true)
        #expect(testSetup.context.manageMemeberViewModel?.state.permissions.canBan == true)
        #expect(testSetup.context.manageMemeberViewModel?.state.isKickDisabled == true)
        #expect(testSetup.context.manageMemeberViewModel?.state.isBanUnbanDisabled == false)
        #expect(testSetup.context.manageMemeberViewModel?.state.isMemberBanned == true)
    }
    
    @Test
    func switchesToMembersModeWhenThereAreNoBannedMembers() async throws {
        // Given the room list viewed as an admin.
        let roomProxy = JoinedRoomProxyMock(.init(name: "test"))
        let subject = CurrentValueSubject<[RoomMemberProxyProtocol], Never>([RoomMemberProxyMock].allMembersAsAdmin + RoomMemberProxyMock.mockBanned)
        roomProxy.membersPublisher = subject.asCurrentValuePublisher()
        let viewModel = RoomMembersListScreenViewModel(userSession: UserSessionMock(.init()),
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
}

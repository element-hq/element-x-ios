//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import XCTest

@testable import ElementX

@MainActor
class RoomMembersListScreenViewModelTests: XCTestCase {
    var viewModel: RoomMembersListScreenViewModel!
    var roomProxy: JoinedRoomProxyMock!
    
    var context: RoomMembersListScreenViewModel.Context {
        viewModel.context
    }
    
    func testJoinedMembers() async throws {
        setup(with: [.mockAlice, .mockBob])
        
        let deferred = deferFulfillment(context.$viewState) { state in
            state.visibleJoinedMembers.count == 2
        }
        
        try await deferred.fulfill()
        
        XCTAssertEqual(viewModel.state.joinedMembersCount, 2)
        XCTAssertEqual(viewModel.state.visibleJoinedMembers.count, 2)
    }
    
    func testSortingMembers() async throws {
        setup(with: [.mockModerator, .mockDan, .mockAlice, .mockAdmin])
        
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
        
        XCTAssertEqual(viewModel.state.visibleJoinedMembers, sortedMembers)
    }
    
    func testSearch() async throws {
        setup(with: [.mockAlice, .mockBob])
        
        let deferred = deferFulfillment(context.$viewState) { state in
            state.visibleJoinedMembers.count == 1
        }
        
        context.searchQuery = "alice"
        
        try await deferred.fulfill()
        
        XCTAssertEqual(viewModel.state.joinedMembersCount, 2)
        XCTAssertEqual(viewModel.state.visibleJoinedMembers.count, 1)
    }
    
    func testEmptySearch() async throws {
        setup(with: [.mockAlice, .mockBob])
        context.searchQuery = "WWW"
        
        let deferred = deferFulfillment(context.$viewState) { state in
            state.joinedMembersCount == 2
        }
        
        try await deferred.fulfill()
        
        XCTAssertEqual(viewModel.state.joinedMembersCount, 2)
        XCTAssertEqual(viewModel.state.visibleJoinedMembers.count, 0)
    }
    
    func testJoinedAndInvitedMembers() async throws {
        setup(with: [.mockInvited, .mockBob])
        
        let deferred = deferFulfillment(context.$viewState) { state in
            state.visibleInvitedMembers.count == 1
        }
        
        try await deferred.fulfill()
        
        XCTAssertEqual(viewModel.state.joinedMembersCount, 1)
        XCTAssertEqual(viewModel.state.visibleInvitedMembers.count, 1)
        XCTAssertEqual(viewModel.state.visibleJoinedMembers.count, 1)
    }
    
    func testInvitedMembers() async throws {
        setup(with: [.mockInvited])
        
        let deferred = deferFulfillment(context.$viewState) { state in
            state.visibleInvitedMembers.count == 1
        }
        
        try await deferred.fulfill()
        
        XCTAssertEqual(viewModel.state.joinedMembersCount, 0)
        XCTAssertEqual(viewModel.state.visibleInvitedMembers.count, 1)
        XCTAssertEqual(viewModel.state.visibleJoinedMembers.count, 0)
    }
    
    func testSearchInvitedMembers() async throws {
        setup(with: [.mockInvited])
        
        context.searchQuery = "invited"
        
        let deferred = deferFulfillment(context.$viewState) { state in
            state.visibleInvitedMembers.count == 1
        }
        
        try await deferred.fulfill()
        
        XCTAssertEqual(viewModel.state.joinedMembersCount, 0)
        XCTAssertEqual(viewModel.state.visibleInvitedMembers.count, 1)
        XCTAssertEqual(viewModel.state.visibleJoinedMembers.count, 0)
    }
    
    func testSelectUserAsUser() async throws {
        // Given the room list viewed as a regular user.
        setup(with: .allMembers)
        let deferred = deferFulfillment(context.$viewState) { !$0.visibleInvitedMembers.isEmpty }
        try await deferred.fulfill()
        
        // When tapping on another user in the list.
        let memberDetailsAction = deferFulfillment(viewModel.actions) { $0.isSelectMember }
        guard let user = viewModel.state.visibleJoinedMembers.first(where: { $0.member.role == .user && $0.member.id != RoomMemberProxyMock.mockMe.userID })?.member else {
            XCTFail("Expected to find a regular user.")
            return
        }
        context.send(viewAction: .selectMember(user))
        
        // Then the member's details should be shown.
        try await memberDetailsAction.fulfill()
        XCTAssertNil(context.manageMemeberViewModel)
    }
    
    func testSelectUserAsAdmin() async throws {
        // Given the room list viewed as an admin.
        setup(with: .allMembersAsAdmin)
        var deferred = deferFulfillment(context.$viewState) { !$0.visibleInvitedMembers.isEmpty && $0.canKickUsers && $0.canBanUsers }
        try await deferred.fulfill()
        XCTAssertNil(context.manageMemeberViewModel)

        // When tapping on a user in the list.
        deferred = deferFulfillment(context.$viewState) { $0.bindings.manageMemeberViewModel != nil }
        guard let user = viewModel.state.visibleJoinedMembers.first(where: { $0.member.role == .user && $0.member.id != RoomMemberProxyMock.mockMe.userID })?.member else {
            XCTFail("Expected to find a regular user.")
            return
        }
        context.send(viewAction: .selectMember(user))
        try await deferred.fulfill()
        
        // Then member management should be shown for that user.
        XCTAssertEqual(context.manageMemeberViewModel?.state.member, user)
        XCTAssertEqual(context.manageMemeberViewModel?.state.canKick, true)
        XCTAssertEqual(context.manageMemeberViewModel?.state.canBan, true)
    }
    
    func testSelectModeratorAsAdmin() async throws {
        // Given the room list viewed as an admin.
        setup(with: .allMembersAsAdmin)
        var deferred = deferFulfillment(context.$viewState) { !$0.visibleInvitedMembers.isEmpty && $0.canKickUsers && $0.canBanUsers }
        try await deferred.fulfill()
        XCTAssertNil(context.manageMemeberViewModel)
        
        // When tapping on a moderator in the list.
        deferred = deferFulfillment(context.$viewState) { $0.bindings.manageMemeberViewModel != nil }
        guard let moderator = viewModel.state.visibleJoinedMembers.first(where: { $0.member.role == .moderator })?.member else {
            XCTFail("Expected to find a moderator.")
            return
        }
        context.send(viewAction: .selectMember(moderator))
        try await deferred.fulfill()
        
        // Then member management should be shown for the moderator.
        XCTAssertEqual(context.manageMemeberViewModel?.state.member, moderator)
        XCTAssertEqual(context.manageMemeberViewModel?.state.canKick, true)
        XCTAssertEqual(context.manageMemeberViewModel?.state.canBan, true)
    }
    
    func testSelectAdminAsAdmin() async throws {
        // Given the room list viewed as an admin.
        setup(with: .allMembersAsAdmin)
        let deferred = deferFulfillment(context.$viewState) { !$0.visibleInvitedMembers.isEmpty }
        try await deferred.fulfill()
        
        // When tapping on another administrator in the list.
        let memberDetailsAction = deferFulfillment(viewModel.actions) { $0.isSelectMember }
        guard let admin = viewModel.state.visibleJoinedMembers.first(where: { $0.member.role == .administrator && $0.member.id != RoomMemberProxyMock.mockMe.userID })?.member else {
            XCTFail("Expected to find another admin.")
            return
        }
        context.send(viewAction: .selectMember(admin))
        
        // Then the administrator's details should be shown.
        try await memberDetailsAction.fulfill()
        XCTAssertNil(context.manageMemeberViewModel)
    }
    
    func testSelectOwnMemberAsAdmin() async throws {
        // Given the room list viewed as an admin.
        setup(with: .allMembersAsAdmin)
        let deferred = deferFulfillment(context.$viewState) { !$0.visibleInvitedMembers.isEmpty }
        try await deferred.fulfill()
        
        // When tapping on yourself in the list.
        let memberDetailsAction = deferFulfillment(viewModel.actions) { $0.isSelectMember }
        guard let ownMember = viewModel.state.visibleJoinedMembers.first(where: { $0.member.id == RoomMemberProxyMock.mockMe.userID })?.member else {
            XCTFail("Expected to find own user admin.")
            return
        }
        context.send(viewAction: .selectMember(ownMember))
        
        // Then your member's details should be shown.
        try await memberDetailsAction.fulfill()
        XCTAssertNil(context.manageMemeberViewModel)
    }
    
    func testSelectBannedMember() async throws {
        // Given the room list viewed as an admin.
        setup(with: .allMembersAsAdmin + RoomMemberProxyMock.mockBanned)
        var deferred = deferFulfillment(context.$viewState) { !$0.visibleInvitedMembers.isEmpty }
        try await deferred.fulfill()
        XCTAssertNil(context.alertInfo)
        
        // When tapping on a banned member in the list.
        deferred = deferFulfillment(context.$viewState) { $0.bindings.alertInfo != nil }
        guard let bannedMember = viewModel.state.visibleBannedMembers.first?.member else {
            XCTFail("Expected to find a banned user.")
            return
        }
        context.send(viewAction: .selectMember(bannedMember))
        
        // Then an alert should be shown to unban the user.
        try await deferred.fulfill()
        XCTAssertNil(context.manageMemeberViewModel)
        XCTAssertNotNil(context.alertInfo)
    }
    
    func testUnbanMember() async throws {
        setup(with: .allMembersAsAdmin)
        let deferred = deferFulfillment(context.$viewState) { !$0.visibleJoinedMembers.isEmpty }
        try await deferred.fulfill()
        
        context.send(viewAction: .unbanMember(viewModel.state.visibleJoinedMembers[0].member))
        
        // Calling the mock won't actually change any view state, so sleep instead.
        try await Task.sleep(for: .milliseconds(100))
        
        XCTAssert(roomProxy.unbanUserCalled)
    }
    
    private func setup(with members: [RoomMemberProxyMock]) {
        roomProxy = JoinedRoomProxyMock(.init(name: "test", members: members))
        viewModel = .init(clientProxy: ClientProxyMock(.init()),
                          roomProxy: roomProxy,
                          mediaProvider: MediaProviderMock(configuration: .init()),
                          userIndicatorController: ServiceLocator.shared.userIndicatorController,
                          analytics: ServiceLocator.shared.analytics)
    }
}

//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
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
        
        let sortedMembers: [RoomMemberProxyMock] = [.mockAdmin, .mockModerator, .mockAlice, .mockDan]
        XCTAssertEqual(viewModel.state.visibleJoinedMembers, sortedMembers.map(RoomMemberDetails.init))
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
        guard let user = viewModel.state.visibleJoinedMembers.first(where: { $0.role == .user && $0.id != RoomMemberProxyMock.mockMe.userID }) else {
            XCTFail("Expected to find a regular user.")
            return
        }
        context.send(viewAction: .selectMember(user))
        
        // Then the member's details should be shown.
        try await memberDetailsAction.fulfill()
        XCTAssertNil(context.memberToManage)
    }
    
    func testSelectUserAsAdmin() async throws {
        // Given the room list viewed as an admin.
        setup(with: .allMembersAsAdmin)
        var deferred = deferFulfillment(context.$viewState) { !$0.visibleInvitedMembers.isEmpty && $0.canKickUsers && $0.canBanUsers }
        try await deferred.fulfill()
        XCTAssertNil(context.memberToManage)
        
        // When tapping on a user in the list.
        deferred = deferFulfillment(context.$viewState) { $0.bindings.memberToManage != nil }
        guard let user = viewModel.state.visibleJoinedMembers.first(where: { $0.role == .user && $0.id != RoomMemberProxyMock.mockMe.userID }) else {
            XCTFail("Expected to find a regular user.")
            return
        }
        context.send(viewAction: .selectMember(user))
        try await deferred.fulfill()
        
        // Then member management should be shown for that user.
        XCTAssertEqual(context.memberToManage?.member, user)
        XCTAssertEqual(context.memberToManage?.actions, [.kick, .ban])
    }
    
    func testSelectModeratorAsAdmin() async throws {
        // Given the room list viewed as an admin.
        setup(with: .allMembersAsAdmin)
        var deferred = deferFulfillment(context.$viewState) { !$0.visibleInvitedMembers.isEmpty && $0.canKickUsers && $0.canBanUsers }
        try await deferred.fulfill()
        XCTAssertNil(context.memberToManage)
        
        // When tapping on a moderator in the list.
        deferred = deferFulfillment(context.$viewState) { $0.bindings.memberToManage != nil }
        guard let moderator = viewModel.state.visibleJoinedMembers.first(where: { $0.role == .moderator }) else {
            XCTFail("Expected to find a moderator.")
            return
        }
        context.send(viewAction: .selectMember(moderator))
        try await deferred.fulfill()
        
        // Then member management should be shown for the moderator.
        XCTAssertEqual(context.memberToManage?.member, moderator)
        XCTAssertEqual(context.memberToManage?.actions, [.kick, .ban])
    }
    
    func testSelectAdminAsAdmin() async throws {
        // Given the room list viewed as an admin.
        setup(with: .allMembersAsAdmin)
        let deferred = deferFulfillment(context.$viewState) { !$0.visibleInvitedMembers.isEmpty }
        try await deferred.fulfill()
        
        // When tapping on another administrator in the list.
        let memberDetailsAction = deferFulfillment(viewModel.actions) { $0.isSelectMember }
        guard let admin = viewModel.state.visibleJoinedMembers.first(where: { $0.role == .administrator && $0.id != RoomMemberProxyMock.mockMe.userID }) else {
            XCTFail("Expected to find another admin.")
            return
        }
        context.send(viewAction: .selectMember(admin))
        
        // Then the administrator's details should be shown.
        try await memberDetailsAction.fulfill()
        XCTAssertNil(context.memberToManage)
    }
    
    func testSelectOwnMemberAsAdmin() async throws {
        // Given the room list viewed as an admin.
        setup(with: .allMembersAsAdmin)
        let deferred = deferFulfillment(context.$viewState) { !$0.visibleInvitedMembers.isEmpty }
        try await deferred.fulfill()
        
        // When tapping on yourself in the list.
        let memberDetailsAction = deferFulfillment(viewModel.actions) { $0.isSelectMember }
        guard let ownMember = viewModel.state.visibleJoinedMembers.first(where: { $0.id == RoomMemberProxyMock.mockMe.userID }) else {
            XCTFail("Expected to find own user admin.")
            return
        }
        context.send(viewAction: .selectMember(ownMember))
        
        // Then your member's details should be shown.
        try await memberDetailsAction.fulfill()
        XCTAssertNil(context.memberToManage)
    }
    
    func testSelectBannedMember() async throws {
        // Given the room list viewed as an admin.
        setup(with: .allMembersAsAdmin + RoomMemberProxyMock.mockBanned)
        var deferred = deferFulfillment(context.$viewState) { !$0.visibleInvitedMembers.isEmpty }
        try await deferred.fulfill()
        XCTAssertNil(context.alertInfo)
        
        // When tapping on a banned member in the list.
        deferred = deferFulfillment(context.$viewState) { $0.bindings.alertInfo != nil }
        guard let bannedMember = viewModel.state.visibleBannedMembers.first else {
            XCTFail("Expected to find a banned user.")
            return
        }
        context.send(viewAction: .selectMember(bannedMember))
        
        // Then an alert should be shown to unban the user.
        try await deferred.fulfill()
        XCTAssertNil(context.memberToManage)
        XCTAssertNotNil(context.alertInfo)
    }
    
    func testKickMember() async throws {
        setup(with: .allMembersAsAdmin)
        let deferred = deferFulfillment(context.$viewState) { !$0.visibleJoinedMembers.isEmpty }
        try await deferred.fulfill()
        
        context.send(viewAction: .kickMember(viewModel.state.visibleJoinedMembers[0]))
        
        // Calling the mock won't actually change any view state, so sleep instead.
        try await Task.sleep(for: .milliseconds(100))
        
        XCTAssert(roomProxy.kickUserCalled)
    }
    
    func testBanMember() async throws {
        setup(with: .allMembersAsAdmin)
        let deferred = deferFulfillment(context.$viewState) { !$0.visibleJoinedMembers.isEmpty }
        try await deferred.fulfill()
        
        context.send(viewAction: .banMember(viewModel.state.visibleJoinedMembers[0]))
        
        // Calling the mock won't actually change any view state, so sleep instead.
        try await Task.sleep(for: .milliseconds(100))
        
        XCTAssert(roomProxy.banUserCalled)
    }
    
    func testUnbanMember() async throws {
        setup(with: .allMembersAsAdmin)
        let deferred = deferFulfillment(context.$viewState) { !$0.visibleJoinedMembers.isEmpty }
        try await deferred.fulfill()
        
        context.send(viewAction: .unbanMember(viewModel.state.visibleJoinedMembers[0]))
        
        // Calling the mock won't actually change any view state, so sleep instead.
        try await Task.sleep(for: .milliseconds(100))
        
        XCTAssert(roomProxy.unbanUserCalled)
    }
    
    private func setup(with members: [RoomMemberProxyMock]) {
        roomProxy = JoinedRoomProxyMock(.init(name: "test", members: members))
        viewModel = .init(roomProxy: roomProxy,
                          mediaProvider: MockMediaProvider(),
                          userIndicatorController: ServiceLocator.shared.userIndicatorController,
                          analytics: ServiceLocator.shared.analytics)
    }
}

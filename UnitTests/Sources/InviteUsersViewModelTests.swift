//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import XCTest

@testable import ElementX

@MainActor
class InviteUsersScreenViewModelTests: XCTestCase {
    var viewModel: InviteUsersScreenViewModelProtocol!
    var userDiscoveryService: UserDiscoveryServiceMock!
        
    var context: InviteUsersScreenViewModel.Context {
        viewModel.context
    }
    
    func testSelectUser() {
        let roomProxy = JoinedRoomProxyMock(.init(name: "newroom", members: []))
        roomProxy.inviteUserIDReturnValue = .success(())
        setupViewModel(roomProxy: roomProxy, isCreatingRoom: true)
        
        XCTAssertTrue(context.viewState.selectedUsers.isEmpty)
        context.send(viewAction: .toggleUser(.mockAlice))
        XCTAssertTrue(context.viewState.selectedUsers.count == 1)
        XCTAssertEqual(context.viewState.selectedUsers.first?.userID, UserProfileProxy.mockAlice.userID)
    }
    
    func testReselectUser() {
        let roomProxy = JoinedRoomProxyMock(.init(name: "newroom", members: []))
        roomProxy.inviteUserIDReturnValue = .success(())
        setupViewModel(roomProxy: roomProxy, isCreatingRoom: true)
        
        XCTAssertTrue(context.viewState.selectedUsers.isEmpty)
        context.send(viewAction: .toggleUser(.mockAlice))
        XCTAssertEqual(context.viewState.selectedUsers.count, 1)
        XCTAssertEqual(context.viewState.selectedUsers.first?.userID, UserProfileProxy.mockAlice.userID)
        context.send(viewAction: .toggleUser(.mockAlice))
        XCTAssertTrue(context.viewState.selectedUsers.isEmpty)
    }
    
    func testDeselectUser() {
        let roomProxy = JoinedRoomProxyMock(.init(name: "newroom", members: []))
        roomProxy.inviteUserIDReturnValue = .success(())
        setupViewModel(roomProxy: roomProxy, isCreatingRoom: true)
        
        XCTAssertTrue(context.viewState.selectedUsers.isEmpty)
        context.send(viewAction: .toggleUser(.mockAlice))
        XCTAssertEqual(context.viewState.selectedUsers.count, 1)
        XCTAssertEqual(context.viewState.selectedUsers.first?.userID, UserProfileProxy.mockAlice.userID)
        context.send(viewAction: .toggleUser(.mockAlice))
        XCTAssertTrue(context.viewState.selectedUsers.isEmpty)
    }
     
    func testInviteButton() async throws {
        let mockedMembers: [RoomMemberProxyMock] = [.mockAlice, .mockBob]
        let roomProxy = JoinedRoomProxyMock(.init(name: "test", members: mockedMembers))
        roomProxy.inviteUserIDReturnValue = .success(())
        setupViewModel(roomProxy: roomProxy, isCreatingRoom: false)
        
        let deferredState = deferFulfillment(viewModel.context.$viewState) { state in
            state.isUserSelected(.mockAlice)
        }
        
        context.send(viewAction: .toggleUser(.mockAlice))
        
        try await deferredState.fulfill()
        
        let deferredAction = deferFulfillment(viewModel.actions) { action in
            switch action {
            case .dismiss:
                return true
            }
        }
        
        context.send(viewAction: .proceed)
        
        try await deferredAction.fulfill()
        XCTAssertEqual(roomProxy.inviteUserIDReceivedInvocations, [RoomMemberProxyMock.mockAlice.userID])
    }
    
    private func setupViewModel(roomProxy: JoinedRoomProxyProtocol, isCreatingRoom: Bool) {
        userDiscoveryService = UserDiscoveryServiceMock()
        userDiscoveryService.searchProfilesWithReturnValue = .success([])
        let viewModel = InviteUsersScreenViewModel(userSession: UserSessionMock(.init()),
                                                   roomProxy: roomProxy,
                                                   isCreatingRoom: isCreatingRoom,
                                                   userDiscoveryService: userDiscoveryService,
                                                   userIndicatorController: UserIndicatorControllerMock(),
                                                   appSettings: ServiceLocator.shared.settings)
        viewModel.state.usersSection = .init(type: .suggestions, users: [.mockAlice, .mockBob, .mockCharlie])
        self.viewModel = viewModel
    }
}

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
struct InviteUsersScreenViewModelTests {
    var viewModel: InviteUsersScreenViewModelProtocol!
    var userDiscoveryService: UserDiscoveryServiceMock!
    
    var context: InviteUsersScreenViewModel.Context {
        viewModel.context
    }
    
    @Test
    mutating func selectUser() {
        let roomProxy = JoinedRoomProxyMock(.init(name: "newroom", members: []))
        roomProxy.inviteUserIDReturnValue = .success(())
        setupViewModel(roomProxy: roomProxy, isSkippable: true)
        
        #expect(context.viewState.selectedUsers.isEmpty)
        context.send(viewAction: .toggleUser(.mockAlice))
        #expect(context.viewState.selectedUsers.count == 1)
        #expect(context.viewState.selectedUsers.first?.userID == UserProfileProxy.mockAlice.userID)
    }
    
    @Test
    mutating func reselectUser() {
        let roomProxy = JoinedRoomProxyMock(.init(name: "newroom", members: []))
        roomProxy.inviteUserIDReturnValue = .success(())
        setupViewModel(roomProxy: roomProxy, isSkippable: true)
        
        #expect(context.viewState.selectedUsers.isEmpty)
        context.send(viewAction: .toggleUser(.mockAlice))
        #expect(context.viewState.selectedUsers.count == 1)
        #expect(context.viewState.selectedUsers.first?.userID == UserProfileProxy.mockAlice.userID)
        context.send(viewAction: .toggleUser(.mockAlice))
        #expect(context.viewState.selectedUsers.isEmpty)
    }
    
    @Test
    mutating func deselectUser() {
        let roomProxy = JoinedRoomProxyMock(.init(name: "newroom", members: []))
        roomProxy.inviteUserIDReturnValue = .success(())
        setupViewModel(roomProxy: roomProxy, isSkippable: true)
        
        #expect(context.viewState.selectedUsers.isEmpty)
        context.send(viewAction: .toggleUser(.mockAlice))
        #expect(context.viewState.selectedUsers.count == 1)
        #expect(context.viewState.selectedUsers.first?.userID == UserProfileProxy.mockAlice.userID)
        context.send(viewAction: .toggleUser(.mockAlice))
        #expect(context.viewState.selectedUsers.isEmpty)
    }
    
    @Test
    mutating func inviteButton() async throws {
        let mockedMembers: [RoomMemberProxyMock] = [.mockAlice, .mockBob]
        let roomProxy = JoinedRoomProxyMock(.init(name: "test", members: mockedMembers))
        roomProxy.inviteUserIDReturnValue = .success(())
        setupViewModel(roomProxy: roomProxy, isSkippable: false)
        
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
        #expect(roomProxy.inviteUserIDReceivedInvocations == [RoomMemberProxyMock.mockAlice.userID])
    }
    
    private mutating func setupViewModel(roomProxy: JoinedRoomProxyProtocol, isSkippable: Bool) {
        userDiscoveryService = UserDiscoveryServiceMock()
        userDiscoveryService.searchProfilesWithReturnValue = .success([])
        let viewModel = InviteUsersScreenViewModel(userSession: UserSessionMock(.init()),
                                                   roomProxy: roomProxy,
                                                   isSkippable: isSkippable,
                                                   userDiscoveryService: userDiscoveryService,
                                                   userIndicatorController: UserIndicatorControllerMock(),
                                                   appSettings: ServiceLocator.shared.settings)
        viewModel.state.usersSection = .init(type: .suggestions, users: [.mockAlice, .mockBob, .mockCharlie])
        self.viewModel = viewModel
    }
}

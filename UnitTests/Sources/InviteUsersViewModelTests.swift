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
final class InviteUsersScreenViewModelTests {
    var viewModel: InviteUsersScreenViewModelProtocol!
    var userDiscoveryService: UserDiscoveryServiceMock!
    var clientProxy: ClientProxyMock!
    
    var context: InviteUsersScreenViewModel.Context {
        viewModel.context
    }
    
    @Test("Toggling an unselected user selects them")
    func selectUser() {
        let roomProxy = JoinedRoomProxyMock(.init(name: "newroom", members: []))
        roomProxy.inviteUserIDReturnValue = .success(())
        setupViewModel(roomProxy: roomProxy, isSkippable: true)
        
        #expect(context.viewState.selectedUsers.isEmpty)
        context.send(viewAction: .toggleUser(.mockAlice))
        #expect(context.viewState.selectedUsers.count == 1)
        #expect(context.viewState.selectedUsers.first?.id == UserProfile.mockAlice.id)
    }
    
    @Test("Toggling a user twice leaves them unselected")
    func reselectUser() {
        let roomProxy = JoinedRoomProxyMock(.init(name: "newroom", members: []))
        roomProxy.inviteUserIDReturnValue = .success(())
        setupViewModel(roomProxy: roomProxy, isSkippable: true)
        
        #expect(context.viewState.selectedUsers.isEmpty)
        context.send(viewAction: .toggleUser(.mockAlice))
        #expect(context.viewState.selectedUsers.count == 1)
        #expect(context.viewState.selectedUsers.first?.id == UserProfile.mockAlice.id)
        context.send(viewAction: .toggleUser(.mockAlice))
        #expect(context.viewState.selectedUsers.isEmpty)
    }
    
    @Test("Toggling a selected user deselects them")
    func deselectUser() {
        let roomProxy = JoinedRoomProxyMock(.init(name: "newroom", members: []))
        roomProxy.inviteUserIDReturnValue = .success(())
        setupViewModel(roomProxy: roomProxy, isSkippable: true)
        
        #expect(context.viewState.selectedUsers.isEmpty)
        context.send(viewAction: .toggleUser(.mockAlice))
        #expect(context.viewState.selectedUsers.count == 1)
        #expect(context.viewState.selectedUsers.first?.id == UserProfile.mockAlice.id)
        context.send(viewAction: .toggleUser(.mockAlice))
        #expect(context.viewState.selectedUsers.isEmpty)
    }
    
    @Test("Proceeding invites the selected users and dismisses the screen")
    func invite() async throws {
        let mockedMembers: [RoomMemberProxyMock] = [.mockBob]
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
            case .openRoom:
                return false
            }
        }
        
        context.send(viewAction: .proceed)
        
        try await deferredAction.fulfill()
        #expect(roomProxy.inviteUserIDReceivedInvocations == [RoomMemberProxyMock.mockAlice.userID])
    }
    
    @Test("Selected users who are already in the room aren't invited again")
    func inviteExistingMembers() async throws {
        let roomProxy = JoinedRoomProxyMock(.init(name: "test", members: [.mockAlice, .mockBob]))
        setupViewModel(roomProxy: roomProxy, isSkippable: false)
        
        let deferredState = deferFulfillment(viewModel.context.$viewState) { state in
            state.membershipState[RoomMemberProxyMock.mockAlice.userID] == .join
                && state.isUserSelected(.mockAlice)
                && state.isUserSelected(.mockCharlie)
        }
        
        context.send(viewAction: .toggleUser(.mockAlice))
        context.send(viewAction: .toggleUser(.mockCharlie))
        
        try await deferredState.fulfill()
        
        let deferredAction = deferFulfillment(viewModel.actions) { $0 == .dismiss }
        context.send(viewAction: .proceed)
        try await deferredAction.fulfill()
        
        #expect(roomProxy.inviteUserIDReceivedInvocations == [RoomMemberProxyMock.mockCharlie.userID])
    }
    
    @Test("The membership state follows live changes to the room's members")
    func membershipUpdates() async throws {
        let roomProxy = JoinedRoomProxyMock(.init(name: "test"))
        let membersSubject = CurrentValueSubject<[RoomMemberProxyProtocol], Never>([RoomMemberProxyMock.mockAlice])
        roomProxy.membersPublisher = membersSubject.asCurrentValuePublisher()
        setupViewModel(roomProxy: roomProxy, isSkippable: false)
        
        var deferredState = deferFulfillment(viewModel.context.$viewState) { state in
            state.membershipState[RoomMemberProxyMock.mockAlice.userID] == .join
        }
        try await deferredState.fulfill()
        #expect(context.viewState.membershipState[RoomMemberProxyMock.mockCharlie.userID] == nil)
        
        deferredState = deferFulfillment(viewModel.context.$viewState) { state in
            state.membershipState[RoomMemberProxyMock.mockCharlie.userID] == .join
        }
        membersSubject.send([RoomMemberProxyMock.mockAlice, RoomMemberProxyMock.mockCharlie])
        try await deferredState.fulfill()
    }
    
    // MARK: - History Sharing
    
    @Test("Inviting users without a known identity asks for confirmation first")
    func inviteUnknownUsers() async throws {
        let mockedMembers: [RoomMemberProxyMock] = [.mockBob]
        let roomProxy = JoinedRoomProxyMock(.init(name: "test", members: mockedMembers))
        roomProxy.inviteUserIDReturnValue = .success(())
        setupViewModel(roomProxy: roomProxy, isSkippable: false)
        
        // Mock the lack of cached user identity
        clientProxy.userIdentityForFallBackToServerReturnValue = .success(nil)
        
        let deferredState = deferFulfillment(viewModel.context.$viewState) { state in
            state.isUserSelected(.mockAlice) && state.usersToConfirm.contains(.mockAlice)
        }
        
        context.send(viewAction: .toggleUser(.mockAlice))
        try await deferredState.fulfill()
        
        context.send(viewAction: .proceed)
        #expect(context.presentConfirmationDialog)
        
        let deferredAction = deferFulfillment(viewModel.actions) { action in
            switch action {
            case .dismiss:
                return true
            case .openRoom:
                return false
            }
        }
        
        context.send(viewAction: .confirmUnknownUsers)
        
        try await deferredAction.fulfill()
        #expect(roomProxy.inviteUserIDReceivedInvocations == [RoomMemberProxyMock.mockAlice.userID])
    }
    
    @Test("Removing unknown users deselects them")
    func removeUnknownUsers() async throws {
        let mockedMembers: [RoomMemberProxyMock] = [.mockAlice, .mockBob]
        let roomProxy = JoinedRoomProxyMock(.init(name: "test", members: mockedMembers))
        roomProxy.inviteUserIDReturnValue = .success(())
        setupViewModel(roomProxy: roomProxy, isSkippable: false)
        
        // Mock the lack of cached user identity
        clientProxy.userIdentityForFallBackToServerReturnValue = .success(nil)
        
        var deferredState = deferFulfillment(viewModel.context.$viewState) { state in
            state.isUserSelected(.mockAlice) && state.usersToConfirm.contains(.mockAlice)
        }
        
        context.send(viewAction: .toggleUser(.mockAlice))
        try await deferredState.fulfill()
        
        context.send(viewAction: .proceed)
        #expect(context.presentConfirmationDialog)
        
        deferredState = deferFulfillment(viewModel.context.$viewState) { state in
            !state.usersToConfirm.contains(.mockAlice) && !state.selectedUsers.contains(.mockAlice)
        }
        
        context.send(viewAction: .removeUnknownUsers)
        try await deferredState.fulfill()
    }
    
    // MARK: - Draft (new room)
    
    @Test("A draft room is created with the selected users when proceeding")
    func createDraftRoom() async throws {
        userDiscoveryService = UserDiscoveryServiceMock()
        userDiscoveryService.searchProfilesWithReturnValue = .success([])
        
        clientProxy = ClientProxyMock(.init(userID: "@mock:client.com"))
        let newRoomID = "!newroom:example.com"
        clientProxy.createRoomReturnValue = .success(newRoomID)
        
        viewModel = InviteUsersScreenViewModel(userSession: UserSessionMock(.init(clientProxy: clientProxy)),
                                               roomType: .draft(mandatoryInvitees: [.mockAlice]),
                                               isSkippable: false,
                                               userDiscoveryService: userDiscoveryService,
                                               userIndicatorController: UserIndicatorControllerMock())
        
        // The locked invitee starts pre-selected and locked.
        #expect(context.viewState.selectedUsers.map(\.id) == [UserProfile.mockAlice.id])
        #expect(context.viewState.isInviteeMandatory(.mockAlice))
        // The proceed button is disabled while the only selected user is the locked invitee.
        #expect(!context.viewState.hasInvitableSelectedUsers)
        
        // Selecting a non-locked user enables the proceed button.
        var deferredState = deferFulfillment(viewModel.context.$viewState) { state in
            state.isUserSelected(.mockBob)
        }
        context.send(viewAction: .toggleUser(.mockBob))
        try await deferredState.fulfill()
        #expect(context.viewState.hasInvitableSelectedUsers)
        
        // Deselecting the non-locked user disables the proceed button again.
        deferredState = deferFulfillment(viewModel.context.$viewState) { state in
            !state.isUserSelected(.mockBob)
        }
        context.send(viewAction: .toggleUser(.mockBob))
        try await deferredState.fulfill()
        #expect(!context.viewState.hasInvitableSelectedUsers)
        
        // Re-select the non-locked user before proceeding.
        deferredState = deferFulfillment(viewModel.context.$viewState) { state in
            state.isUserSelected(.mockBob)
        }
        context.send(viewAction: .toggleUser(.mockBob))
        try await deferredState.fulfill()
        
        let deferredAction = deferFulfillment(viewModel.actions) { action in
            if case .openRoom(let roomID) = action, roomID == newRoomID {
                return true
            }
            return false
        }
        
        context.send(viewAction: .proceed)
        
        try await deferredAction.fulfill()
        
        let parameters = try #require(clientProxy.createRoomReceivedParameters)
        #expect(parameters.name == nil)
        #expect(parameters.topic == nil)
        #expect(parameters.preset == .privateChat)
        #expect(parameters.joinRuleOverride == nil)
        #expect(parameters.isSpace == false)
        #expect(parameters.userIDs == [UserProfile.mockAlice.id, UserProfile.mockBob.id])
        #expect(parameters.avatarURL == nil)
        #expect(parameters.aliasLocalPart == nil)
    }
    
    // MARK: - Helpers
    
    private func setupViewModel(roomProxy: JoinedRoomProxyProtocol, isSkippable: Bool) {
        userDiscoveryService = UserDiscoveryServiceMock()
        userDiscoveryService.searchProfilesWithReturnValue = .success([])
        
        clientProxy = ClientProxyMock(.init(userID: "@mock:client.com"))
        
        let viewModel = InviteUsersScreenViewModel(userSession: UserSessionMock(.init(clientProxy: clientProxy)),
                                                   roomType: .existingRoom(roomProxy: roomProxy),
                                                   isSkippable: isSkippable,
                                                   userDiscoveryService: userDiscoveryService,
                                                   userIndicatorController: UserIndicatorControllerMock())
        viewModel.state.usersSection = .init(type: .suggestions, users: [.mockAlice, .mockBob, .mockCharlie])
        self.viewModel = viewModel
    }
}

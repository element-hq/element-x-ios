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
final class CreateRoomScreenViewModelTests {
    var viewModel: CreateRoomScreenViewModelProtocol!
    var clientProxy: ClientProxyMock!
    var spaceService: SpaceServiceProxyMock!
    var userSession: UserSessionMock!
    
    private let usersSubject = CurrentValueSubject<[UserProfileProxy], Never>([])
    
    var context: CreateRoomScreenViewModel.Context {
        viewModel.context
    }
    
    deinit {
        AppSettings.resetAllSettings()
        viewModel = nil
        clientProxy = nil
        spaceService = nil
        userSession = nil
    }
    
    @Test
    func defaultState() {
        setup()
        #expect(context.viewState.bindings.selectedAccessType == .private)
        #expect(context.selectedSpace == nil)
        #expect(context.viewState.availableAccessTypes == [.public, .askToJoin, .private])
        #expect(context.viewState.canSelectSpace)
    }
    
    @Test
    func createRoomRequirements() {
        setup()
        #expect(!context.viewState.canCreateRoom)
        context.send(viewAction: .updateRoomName("A"))
        #expect(context.viewState.canCreateRoom)
    }
    
    @Test
    func createRoom() async throws {
        setup()
        // Given a form with a blank topic.
        context.send(viewAction: .updateRoomName("A"))
        context.roomTopic = ""
        context.selectedAccessType = .private
        #expect(context.viewState.canCreateRoom)
        
        // When creating the room.
        clientProxy.createRoomNameTopicAccessTypeIsSpaceUserIDsAvatarURLAliasLocalPartReturnValue = .success("1")
        let deferred = deferFulfillment(viewModel.actions) { action in
            guard case .createdRoom(let roomProxy, nil) = action, roomProxy.id == "1" else { return false }
            return true
        }
        context.send(viewAction: .createRoom)
        try await deferred.fulfill()
        
        // Then the room should be created and a topic should not be set.
        #expect(clientProxy.createRoomNameTopicAccessTypeIsSpaceUserIDsAvatarURLAliasLocalPartCalled)
        #expect(clientProxy.createRoomNameTopicAccessTypeIsSpaceUserIDsAvatarURLAliasLocalPartReceivedArguments?.name == "A")
        #expect(clientProxy.createRoomNameTopicAccessTypeIsSpaceUserIDsAvatarURLAliasLocalPartReceivedArguments?.topic == nil,
                "The topic should be sent as nil when it is empty.")
        #expect(clientProxy.createRoomNameTopicAccessTypeIsSpaceUserIDsAvatarURLAliasLocalPartReceivedArguments?.accessType == .private)
    }
    
    @Test
    func createSpace() async throws {
        setup(isSpace: true)
        clientProxy = ClientProxyMock(.init(userIDServerName: "matrix.org",
                                            userID: "@a:b.com",
                                            spaceServiceConfiguration: .init(spaceRoomLists: ["1": .init()])))
        clientProxy.roomForIdentifierClosure = { roomID in .joined(JoinedRoomProxyMock(.init(id: roomID))) }
        userSession = UserSessionMock(.init(clientProxy: clientProxy))
        ServiceLocator.shared.settings.knockingEnabled = true
        let viewModel = CreateRoomScreenViewModel(isSpace: true,
                                                  spaceSelectionMode: .none,
                                                  shouldShowCancelButton: false,
                                                  userSession: userSession,
                                                  analytics: ServiceLocator.shared.analytics,
                                                  userIndicatorController: UserIndicatorControllerMock(),
                                                  appSettings: ServiceLocator.shared.settings)
        self.viewModel = viewModel
        
        // Given a form with a blank topic.
        context.send(viewAction: .updateRoomName("A"))
        context.roomTopic = ""
        context.selectedAccessType = .private
        #expect(context.viewState.canCreateRoom)
        
        // When creating the room.
        clientProxy.createRoomNameTopicAccessTypeIsSpaceUserIDsAvatarURLAliasLocalPartReturnValue = .success("1")
        let deferred = deferFulfillment(viewModel.actions) { action in
            guard case .createdRoom(let roomProxy, let spaceRoomListProxy) = action,
                  spaceRoomListProxy != nil,
                  roomProxy.id == "1" else { return false }
            return true
        }
        context.send(viewAction: .createRoom)
        try await deferred.fulfill()
        
        // Then the room should be created and a topic should not be set.
        #expect(clientProxy.createRoomNameTopicAccessTypeIsSpaceUserIDsAvatarURLAliasLocalPartCalled)
        #expect(clientProxy.createRoomNameTopicAccessTypeIsSpaceUserIDsAvatarURLAliasLocalPartReceivedArguments?.name == "A")
        #expect(clientProxy.createRoomNameTopicAccessTypeIsSpaceUserIDsAvatarURLAliasLocalPartReceivedArguments?.topic == nil,
                "The topic should be sent as nil when it is empty.")
        #expect(clientProxy.createRoomNameTopicAccessTypeIsSpaceUserIDsAvatarURLAliasLocalPartReceivedArguments?.accessType == .private)
    }
    
    @Test
    func createKnockingRoom() async {
        setup()
        context.send(viewAction: .updateRoomName("A"))
        context.roomTopic = "B"
        context.selectedAccessType = .askToJoin
        // When setting the room as private we always reset the knocking state to the default value of false
        // so we need to wait a main actor cycle to ensure the view state is updated
        await Task.yield()
        #expect(context.viewState.canCreateRoom)
        
        await waitForConfirmation("Wait for the room to be created") { confirmation in
            clientProxy.createRoomNameTopicAccessTypeIsSpaceUserIDsAvatarURLAliasLocalPartClosure = { _, _, accessType, _, _, _, localAliasPart in
                #expect(accessType == .askToJoin)
                #expect(localAliasPart == "a")
                defer { confirmation() }
                return .success("")
            }
            context.send(viewAction: .createRoom)
        }
    }
    
    @Test
    func createPublicRoomFailsForInvalidAlias() async throws {
        setup()
        context.send(viewAction: .updateRoomName("A"))
        context.roomTopic = "B"
        context.selectedAccessType = .public
        // When setting the room as private we always reset the alias
        // so we need to wait a main actor cycle to ensure the view state is updated
        await Task.yield()
        
        // we wait for the debounce to show the error
        let deferred = deferFulfillment(context.$viewState) { viewState in
            viewState.aliasErrors.contains(.invalidSymbols) && !viewState.canCreateRoom
        }
        context.send(viewAction: .updateAliasLocalPart("#:"))
        try await deferred.fulfill()
        
        // We also want to force the room creation in case the user may tap the button before the debounce
        // blocked it
        context.send(viewAction: .createRoom)
        await Task.yield()
        #expect(!clientProxy.createRoomNameTopicAccessTypeIsSpaceUserIDsAvatarURLAliasLocalPartCalled)
    }
    
    @Test
    func createPublicRoomFailsForExistingAlias() async throws {
        setup()
        clientProxy.isAliasAvailableReturnValue = .success(false)
        context.send(viewAction: .updateRoomName("A"))
        context.roomTopic = "B"
        context.selectedAccessType = .public
        // When setting the room as private we always reset the alias
        // so we need to wait a main actor cycle to ensure the view state is updated
        await Task.yield()
        
        // we wait for the debounce to show the error
        let deferred = deferFulfillment(context.$viewState) { viewState in
            viewState.aliasErrors.contains(.alreadyExists) && !viewState.canCreateRoom
        }
        context.send(viewAction: .updateAliasLocalPart("abc"))
        try await deferred.fulfill()
        
        // We also want to force the room creation in case the user may tap the button before the debounce
        // blocked it
        await waitForConfirmation("Wait for the alias to be checked again") { confirmation in
            clientProxy.isAliasAvailableClosure = { _ in
                defer { confirmation() }
                return .success(false)
            }
            context.send(viewAction: .createRoom)
        }
        #expect(clientProxy.isAliasAvailableCallsCount == 2)
        #expect(!clientProxy.createRoomNameTopicAccessTypeIsSpaceUserIDsAvatarURLAliasLocalPartCalled)
    }
    
    @Test
    func nameAndAddressSync() async {
        setup()
        context.selectedAccessType = .private
        await Task.yield()
        context.send(viewAction: .updateRoomName("abc"))
        #expect(context.viewState.aliasLocalPart == "abc")
        #expect(context.viewState.roomName == "abc")
        context.send(viewAction: .updateRoomName("DEF"))
        #expect(context.viewState.roomName == "DEF")
        #expect(context.viewState.aliasLocalPart == "def")
        context.send(viewAction: .updateRoomName("a  b c"))
        #expect(context.viewState.aliasLocalPart == "a-b-c")
        #expect(context.viewState.roomName == "a  b c")
        context.send(viewAction: .updateAliasLocalPart("hello-world"))
        // This removes the sync
        #expect(context.viewState.aliasLocalPart == "hello-world")
        #expect(context.viewState.roomName == "a  b c")
        
        context.send(viewAction: .updateRoomName("Hello Matrix!"))
        #expect(context.viewState.aliasLocalPart == "hello-world")
        #expect(context.viewState.roomName == "Hello Matrix!")
        
        // Deleting the whole name will restore the sync
        context.send(viewAction: .updateRoomName(""))
        #expect(context.viewState.aliasLocalPart == "")
        #expect(context.viewState.roomName == "")
        
        context.send(viewAction: .updateRoomName("Hello# Matrix!"))
        #expect(context.viewState.aliasLocalPart == "hello-matrix!")
        #expect(context.viewState.roomName == "Hello# Matrix!")
    }
    
    @Test
    func createRoomInASelectedSpaceFromTheList() async throws {
        let spaces = [SpaceServiceRoom].mockJoinedSpaces2
        setup()
        
        context.send(viewAction: .updateRoomName("A"))
        context.selectedAccessType = .public
        #expect(context.viewState.canCreateRoom)
        #expect(context.selectedSpace == nil)
        #expect(context.viewState.availableAccessTypes == [.public, .askToJoin, .private])
        #expect(context.viewState.canSelectSpace)
        
        var deferred = deferFulfillment(context.$viewState) { viewState in
            viewState.editableSpaces.map(\.id) == spaces.map(\.id)
        }
        try await deferred.fulfill()
        
        context.selectedSpace = spaces[0]
        deferred = deferFulfillment(context.$viewState) { viewState in
            viewState.bindings.selectedSpace?.id == spaces[0].id &&
                viewState.availableAccessTypes == [.spaceMembers, .askToJoinWithSpaceMembers, .private] &&
                // The value should reset since the original one is not available anymore
                viewState.bindings.selectedAccessType == .private
        }
        try await deferred.fulfill()
        
        // When creating the room.
        clientProxy.createRoomNameTopicAccessTypeIsSpaceUserIDsAvatarURLAliasLocalPartReturnValue = .success("1")
        try await confirmation("Wait for the addChild function to be called") { confirm in
            let deferredAction = deferFulfillment(viewModel.actions) { action in
                guard case .createdRoom(let roomProxy, nil) = action, roomProxy.id == "1" else { return false }
                return true
            }
            spaceService.addChildToClosure = { roomID, spaceID in
                defer { confirm() }
                #expect(roomID == "1")
                #expect(spaceID == spaces[0].id)
                return .success(())
            }
            context.send(viewAction: .createRoom)
            try await deferredAction.fulfill()
        }
        
        #expect(clientProxy.createRoomNameTopicAccessTypeIsSpaceUserIDsAvatarURLAliasLocalPartCalled)
        #expect(clientProxy.createRoomNameTopicAccessTypeIsSpaceUserIDsAvatarURLAliasLocalPartReceivedArguments?.name == "A")
        #expect(clientProxy.createRoomNameTopicAccessTypeIsSpaceUserIDsAvatarURLAliasLocalPartReceivedArguments?.accessType == .private)
    }
    
    @Test
    func createRoomInAnAlreadySelectedSpace() async throws {
        let space = SpaceServiceRoom.mock(isSpace: true, joinRule: .invite)
        setup(spacesSelectionMode: .editableSpacesList(preSelectedSpace: space))
        
        context.send(viewAction: .updateRoomName("A"))
        context.selectedAccessType = .spaceMembers
        #expect(context.viewState.canCreateRoom)
        #expect(context.selectedSpace?.id == space.id)
        #expect(context.viewState.availableAccessTypes == [.spaceMembers, .askToJoinWithSpaceMembers, .private])
        #expect(context.viewState.canSelectSpace)
        
        // When creating the room.
        clientProxy.createRoomNameTopicAccessTypeIsSpaceUserIDsAvatarURLAliasLocalPartReturnValue = .success("1")
        try await confirmation("Wait for the addChild function to be called") { confirm in
            let deferredAction = deferFulfillment(viewModel.actions) { action in
                guard case .createdRoom(let roomProxy, nil) = action, roomProxy.id == "1" else { return false }
                return true
            }
            spaceService.addChildToClosure = { roomID, spaceID in
                defer { confirm() }
                #expect(roomID == "1")
                #expect(spaceID == space.id)
                return .success(())
            }
            context.send(viewAction: .createRoom)
            try await deferredAction.fulfill()
        }
        
        #expect(clientProxy.createRoomNameTopicAccessTypeIsSpaceUserIDsAvatarURLAliasLocalPartCalled)
        #expect(clientProxy.createRoomNameTopicAccessTypeIsSpaceUserIDsAvatarURLAliasLocalPartReceivedArguments?.name == "A")
        #expect(clientProxy.createRoomNameTopicAccessTypeIsSpaceUserIDsAvatarURLAliasLocalPartReceivedArguments?.accessType == .spaceMembers(spaceID: space.id))
    }
    
    @Test
    func createRoomInAnPublicSpaceAvailableTypes() {
        let space = SpaceServiceRoom.mock(isSpace: true, joinRule: .public)
        setup(spacesSelectionMode: .editableSpacesList(preSelectedSpace: space))
        
        // Given a form with a blank topic.
        context.send(viewAction: .updateRoomName("A"))
        context.roomTopic = ""
        context.selectedAccessType = .spaceMembers
        #expect(context.viewState.canCreateRoom)
        #expect(context.selectedSpace?.id == space.id)
        #expect(context.viewState.availableAccessTypes == [.public, .askToJoin, .private])
        #expect(context.viewState.canSelectSpace)
    }
    
    private func setup(isSpace: Bool = false, spacesSelectionMode: CreateRoomScreenSpaceSelectionMode = .editableSpacesList(preSelectedSpace: nil)) {
        spaceService = SpaceServiceProxyMock(.init(editableSpaces: .mockJoinedSpaces2,
                                                   spaceRoomLists: ["1": .init()]))
        clientProxy = ClientProxyMock(.init(userIDServerName: "matrix.org",
                                            userID: "@a:b.com"))
        clientProxy.spaceService = spaceService
        clientProxy.roomForIdentifierClosure = { roomID in .joined(JoinedRoomProxyMock(.init(id: roomID))) }
        userSession = UserSessionMock(.init(clientProxy: clientProxy))
        ServiceLocator.shared.settings.knockingEnabled = true
        let viewModel = CreateRoomScreenViewModel(isSpace: isSpace,
                                                  spaceSelectionMode: spacesSelectionMode,
                                                  shouldShowCancelButton: false,
                                                  userSession: userSession,
                                                  analytics: ServiceLocator.shared.analytics,
                                                  userIndicatorController: UserIndicatorControllerMock(),
                                                  appSettings: ServiceLocator.shared.settings)
        self.viewModel = viewModel
    }
}

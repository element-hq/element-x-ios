//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
@testable import ElementX
import XCTest

@MainActor
class CreateRoomScreenViewModelTests: XCTestCase {
    var viewModel: CreateRoomScreenViewModelProtocol!
    var clientProxy: ClientProxyMock!
    var spaceService: SpaceServiceProxyMock!
    var userSession: UserSessionMock!
    
    private let usersSubject = CurrentValueSubject<[UserProfileProxy], Never>([])
    
    var context: CreateRoomScreenViewModel.Context {
        viewModel.context
    }
    
    override func tearDown() {
        AppSettings.resetAllSettings()
        viewModel = nil
        clientProxy = nil
        spaceService = nil
        userSession = nil
    }
    
    func testDefaultState() {
        setup()
        XCTAssertEqual(context.viewState.bindings.selectedAccessType, .private)
        XCTAssertNil(context.selectedSpace)
        XCTAssertEqual(context.viewState.availableAccessTypes, [.public, .askToJoin, .private])
        XCTAssertTrue(context.viewState.canSelectSpace)
    }
    
    func testCreateRoomRequirements() {
        setup()
        XCTAssertFalse(context.viewState.canCreateRoom)
        context.send(viewAction: .updateRoomName("A"))
        XCTAssertTrue(context.viewState.canCreateRoom)
    }
    
    func testCreateRoom() async throws {
        setup()
        // Given a form with a blank topic.
        context.send(viewAction: .updateRoomName("A"))
        context.roomTopic = ""
        context.selectedAccessType = .private
        XCTAssertTrue(context.viewState.canCreateRoom)
        
        // When creating the room.
        clientProxy.createRoomNameTopicAccessTypeIsSpaceUserIDsAvatarURLAliasLocalPartReturnValue = .success("1")
        let deferred = deferFulfillment(viewModel.actions) { action in
            guard case .createdRoom(let roomProxy, nil) = action, roomProxy.id == "1" else { return false }
            return true
        }
        context.send(viewAction: .createRoom)
        try await deferred.fulfill()
        
        // Then the room should be created and a topic should not be set.
        XCTAssertTrue(clientProxy.createRoomNameTopicAccessTypeIsSpaceUserIDsAvatarURLAliasLocalPartCalled)
        XCTAssertEqual(clientProxy.createRoomNameTopicAccessTypeIsSpaceUserIDsAvatarURLAliasLocalPartReceivedArguments?.name, "A")
        XCTAssertNil(clientProxy.createRoomNameTopicAccessTypeIsSpaceUserIDsAvatarURLAliasLocalPartReceivedArguments?.topic,
                     "The topic should be sent as nil when it is empty.")
        XCTAssertEqual(clientProxy.createRoomNameTopicAccessTypeIsSpaceUserIDsAvatarURLAliasLocalPartReceivedArguments?.accessType, .private)
    }
    
    func testCreateSpace() async throws {
        setup(isSpace: true)
        clientProxy = ClientProxyMock(.init(userIDServerName: "matrix.org",
                                            userID: "@a:b.com",
                                            spaceServiceConfiguration: .init(spaceRoomLists: ["1": .init()])))
        clientProxy.roomForIdentifierClosure = { roomID in .joined(JoinedRoomProxyMock(.init(id: roomID))) }
        userSession = UserSessionMock(.init(clientProxy: clientProxy))
        ServiceLocator.shared.settings.knockingEnabled = true
        let viewModel = CreateRoomScreenViewModel(isSpace: true,
                                                  spaceSelectionMode: nil,
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
        XCTAssertTrue(context.viewState.canCreateRoom)
        
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
        XCTAssertTrue(clientProxy.createRoomNameTopicAccessTypeIsSpaceUserIDsAvatarURLAliasLocalPartCalled)
        XCTAssertEqual(clientProxy.createRoomNameTopicAccessTypeIsSpaceUserIDsAvatarURLAliasLocalPartReceivedArguments?.name, "A")
        XCTAssertNil(clientProxy.createRoomNameTopicAccessTypeIsSpaceUserIDsAvatarURLAliasLocalPartReceivedArguments?.topic,
                     "The topic should be sent as nil when it is empty.")
        XCTAssertEqual(clientProxy.createRoomNameTopicAccessTypeIsSpaceUserIDsAvatarURLAliasLocalPartReceivedArguments?.accessType, .private)
    }
    
    func testCreateKnockingRoom() async {
        setup()
        context.send(viewAction: .updateRoomName("A"))
        context.roomTopic = "B"
        context.selectedAccessType = .askToJoin
        // When setting the room as private we always reset the knocking state to the default value of false
        // so we need to wait a main actor cycle to ensure the view state is updated
        await Task.yield()
        XCTAssertTrue(context.viewState.canCreateRoom)
        
        let expectation = expectation(description: "Wait for the room to be created")
        clientProxy.createRoomNameTopicAccessTypeIsSpaceUserIDsAvatarURLAliasLocalPartClosure = { _, _, accessType, _, _, _, localAliasPart in
            XCTAssertEqual(accessType, .askToJoin)
            XCTAssertEqual(localAliasPart, "a")
            defer { expectation.fulfill() }
            return .success("")
        }
        context.send(viewAction: .createRoom)
        await fulfillment(of: [expectation])
    }
    
    func testCreatePublicRoomFailsForInvalidAlias() async throws {
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
        XCTAssertFalse(clientProxy.createRoomNameTopicAccessTypeIsSpaceUserIDsAvatarURLAliasLocalPartCalled)
    }
    
    func testCreatePublicRoomFailsForExistingAlias() async throws {
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
        let expectation = expectation(description: "Wait for the alias to be checked again")
        clientProxy.isAliasAvailableClosure = { _ in
            defer {
                expectation.fulfill()
            }
            return .success(false)
        }
        context.send(viewAction: .createRoom)
        await fulfillment(of: [expectation])
        XCTAssertEqual(clientProxy.isAliasAvailableCallsCount, 2)
        XCTAssertFalse(clientProxy.createRoomNameTopicAccessTypeIsSpaceUserIDsAvatarURLAliasLocalPartCalled)
    }
    
    func testNameAndAddressSync() async {
        setup()
        context.selectedAccessType = .private
        await Task.yield()
        context.send(viewAction: .updateRoomName("abc"))
        XCTAssertEqual(context.viewState.aliasLocalPart, "abc")
        XCTAssertEqual(context.viewState.roomName, "abc")
        context.send(viewAction: .updateRoomName("DEF"))
        XCTAssertEqual(context.viewState.roomName, "DEF")
        XCTAssertEqual(context.viewState.aliasLocalPart, "def")
        context.send(viewAction: .updateRoomName("a  b c"))
        XCTAssertEqual(context.viewState.aliasLocalPart, "a-b-c")
        XCTAssertEqual(context.viewState.roomName, "a  b c")
        context.send(viewAction: .updateAliasLocalPart("hello-world"))
        // This removes the sync
        XCTAssertEqual(context.viewState.aliasLocalPart, "hello-world")
        XCTAssertEqual(context.viewState.roomName, "a  b c")
        
        context.send(viewAction: .updateRoomName("Hello Matrix!"))
        XCTAssertEqual(context.viewState.aliasLocalPart, "hello-world")
        XCTAssertEqual(context.viewState.roomName, "Hello Matrix!")
        
        // Deleting the whole name will restore the sync
        context.send(viewAction: .updateRoomName(""))
        XCTAssertEqual(context.viewState.aliasLocalPart, "")
        XCTAssertEqual(context.viewState.roomName, "")
        
        context.send(viewAction: .updateRoomName("Hello# Matrix!"))
        XCTAssertEqual(context.viewState.aliasLocalPart, "hello-matrix!")
        XCTAssertEqual(context.viewState.roomName, "Hello# Matrix!")
    }
    
    func testCreateRoomInASelectedSpaceFromTheList() async throws {
        let spaces = [SpaceServiceRoom].mockJoinedSpaces2
        setup()
        
        context.send(viewAction: .updateRoomName("A"))
        context.selectedAccessType = .public
        XCTAssertTrue(context.viewState.canCreateRoom)
        XCTAssertNil(context.selectedSpace)
        XCTAssertEqual(context.viewState.availableAccessTypes, [.public, .askToJoin, .private])
        XCTAssertTrue(context.viewState.canSelectSpace)
        
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
        let expectation = expectation(description: "Wait for the addChild function to be called")
        spaceService.addChildToClosure = { roomID, spaceID in
            defer { expectation.fulfill() }
            XCTAssertEqual(roomID, "1")
            XCTAssertEqual(spaceID, spaces[0].id)
            return .success(())
        }
        
        let deferredAction = deferFulfillment(viewModel.actions) { action in
            guard case .createdRoom(let roomProxy, nil) = action, roomProxy.id == "1" else { return false }
            return true
        }
        context.send(viewAction: .createRoom)
        
        await fulfillment(of: [expectation])
        try await deferredAction.fulfill()
        
        XCTAssertTrue(clientProxy.createRoomNameTopicAccessTypeIsSpaceUserIDsAvatarURLAliasLocalPartCalled)
        XCTAssertEqual(clientProxy.createRoomNameTopicAccessTypeIsSpaceUserIDsAvatarURLAliasLocalPartReceivedArguments?.name, "A")
        XCTAssertEqual(clientProxy.createRoomNameTopicAccessTypeIsSpaceUserIDsAvatarURLAliasLocalPartReceivedArguments?.accessType, .private)
    }
    
    func testCreateRoomInAnAlreadySelectedSpace() async throws {
        let space = SpaceServiceRoom.mock(isSpace: true, joinRule: .invite)
        setup(spacesSelectionMode: .preSelected(space))
        
        context.send(viewAction: .updateRoomName("A"))
        context.selectedAccessType = .spaceMembers
        XCTAssertTrue(context.viewState.canCreateRoom)
        XCTAssertEqual(context.selectedSpace?.id, space.id)
        XCTAssertEqual(context.viewState.availableAccessTypes, [.spaceMembers, .askToJoinWithSpaceMembers, .private])
        XCTAssertFalse(context.viewState.canSelectSpace)
        
        // When creating the room.
        clientProxy.createRoomNameTopicAccessTypeIsSpaceUserIDsAvatarURLAliasLocalPartReturnValue = .success("1")
        let expectation = expectation(description: "Wait for the addChild function to be called")
        spaceService.addChildToClosure = { roomID, spaceID in
            defer { expectation.fulfill() }
            XCTAssertEqual(roomID, "1")
            XCTAssertEqual(spaceID, space.id)
            return .success(())
        }
        
        let deferredAction = deferFulfillment(viewModel.actions) { action in
            guard case .createdRoom(let roomProxy, nil) = action, roomProxy.id == "1" else { return false }
            return true
        }
        context.send(viewAction: .createRoom)
        
        await fulfillment(of: [expectation])
        try await deferredAction.fulfill()
        
        XCTAssertTrue(clientProxy.createRoomNameTopicAccessTypeIsSpaceUserIDsAvatarURLAliasLocalPartCalled)
        XCTAssertEqual(clientProxy.createRoomNameTopicAccessTypeIsSpaceUserIDsAvatarURLAliasLocalPartReceivedArguments?.name, "A")
        XCTAssertEqual(clientProxy.createRoomNameTopicAccessTypeIsSpaceUserIDsAvatarURLAliasLocalPartReceivedArguments?.accessType, .spaceMembers(spaceID: space.id))
    }
    
    func testCreateRoomInAnPublicSpaceAvailableTypes() {
        let space = SpaceServiceRoom.mock(isSpace: true, joinRule: .public)
        setup(spacesSelectionMode: .preSelected(space))
        
        // Given a form with a blank topic.
        context.send(viewAction: .updateRoomName("A"))
        context.roomTopic = ""
        context.selectedAccessType = .spaceMembers
        XCTAssertTrue(context.viewState.canCreateRoom)
        XCTAssertEqual(context.selectedSpace?.id, space.id)
        XCTAssertEqual(context.viewState.availableAccessTypes, [.public, .askToJoin, .private])
        XCTAssertFalse(context.viewState.canSelectSpace)
    }
    
    private func setup(isSpace: Bool = false, spacesSelectionMode: CreateRoomScreenSpaceSelectionMode = .editableSpacesList) {
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

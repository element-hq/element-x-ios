//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
@testable import ElementX
import MatrixRustSDK
import MatrixRustSDKMocks
import XCTest

@MainActor
class SpaceScreenViewModelTests: XCTestCase {
    var spaceRoomListProxy: SpaceRoomListProxyMock!
    var spaceServiceProxy: SpaceServiceProxyMock!
    let mockSpaceRooms = [SpaceServiceRoom].mockSpaceList
    var clientProxy: ClientProxyMock!
    var paginationStateSubject: CurrentValueSubject<SpaceRoomListPaginationState, Never> = .init(.idle(endReached: true))
    var rustLeaveHandle: LeaveSpaceHandleSDKMock!
    
    var viewModel: SpaceScreenViewModelProtocol!
    
    var context: SpaceScreenViewModelType.Context {
        viewModel.context
    }

    func testInitialState() {
        setupViewModel()
        
        XCTAssertEqual(context.viewState.paginationState, .idle)
        XCTAssertTrue(context.viewState.rooms.isEmpty)
        XCTAssertFalse(spaceRoomListProxy.paginateCalled)
    }
    
    func testSinglePagination() async throws {
        // Given a space screen view model for a space with a single paginations worth of children.
        let response = mockSpaceRooms.prefix(3)
        setupViewModel(paginationResponses: [Array(response)])
        
        XCTAssertEqual(context.viewState.paginationState, .idle)
        XCTAssertTrue(context.viewState.rooms.isEmpty)
        XCTAssertFalse(spaceRoomListProxy.paginateCalled)
        XCTAssertFalse(response.isEmpty, "There should be some test rooms.")
        
        // When the pagination is triggered.
        var deferred = deferFulfillment(spaceRoomListProxy.paginationStatePublisher) { $0 == .loading }
        paginationStateSubject.send(.idle(endReached: false)) // Invert the default to allow paginate to be called.
        try await deferred.fulfill()
        
        // Then the screen should show a paginating indicator.
        XCTAssertEqual(context.viewState.paginationState, .paginating)
        XCTAssertEqual(spaceRoomListProxy.paginateCallsCount, 1)
        
        // When waiting for the pagination to finish.
        deferred = deferFulfillment(spaceRoomListProxy.paginationStatePublisher) { $0 == .idle(endReached: true) }
        try await deferred.fulfill()
        
        // Then no more pagination requests should be made the the space rooms should be populated.
        XCTAssertEqual(context.viewState.paginationState, .endReached)
        XCTAssertEqual(spaceRoomListProxy.paginateCallsCount, 1)
        XCTAssertEqual(context.viewState.rooms.map(\.id), response.map(\.id))
    }
    
    func testMultiplePaginations() async throws {
        // Given a space screen view model for a space with two distinct paginations worth of children.
        let response1 = mockSpaceRooms.prefix(3)
        let response2 = mockSpaceRooms.suffix(mockSpaceRooms.count - 3)
        setupViewModel(paginationResponses: [Array(response1), Array(response2)])
        
        XCTAssertEqual(context.viewState.paginationState, .idle)
        XCTAssertTrue(context.viewState.rooms.isEmpty)
        XCTAssertFalse(spaceRoomListProxy.paginateCalled)
        XCTAssertFalse(response1.isEmpty, "There should be some test rooms.")
        XCTAssertFalse(response2.isEmpty, "There should be more test rooms.")
        
        // When the pagination is triggered.
        let deferredIsPaginating = deferFulfillment(context.observe(\.viewState.paginationState), transitionValues: [.paginating, .idle, .paginating, .endReached])
        let deferredState = deferFulfillment(spaceRoomListProxy.paginationStatePublisher, keyPath: \.self, transitionValues: [.loading,
                                                                                                                              .idle(endReached: false),
                                                                                                                              .loading,
                                                                                                                              .idle(endReached: true)])
        paginationStateSubject.send(.idle(endReached: false)) // Invert the default to allow paginate to be called.
        
        // Then the screen should show 2 distinct paginations and finish up with all of the rooms visible.
        try await deferredIsPaginating.fulfill()
        try await deferredState.fulfill()
        
        XCTAssertEqual(context.viewState.paginationState, .endReached)
        XCTAssertEqual(spaceRoomListProxy.paginateCallsCount, 2)
        XCTAssertEqual(context.viewState.rooms.map(\.id), mockSpaceRooms.map(\.id))
    }
    
    func testSelectingSpace() async throws {
        setupViewModel()
        
        let selectedSpace = try XCTUnwrap(mockSpaceRooms.first { $0.isSpace && $0.state == .joined }, "There should be a space to select.")
        let deferred = deferFulfillment(viewModel.actionsPublisher) { _ in true }
        viewModel.context.send(viewAction: .spaceAction(.select(selectedSpace)))
        let action = try await deferred.fulfill()
        
        switch action {
        case .selectSpace(let spaceRoomListProxy) where spaceRoomListProxy.id == selectedSpace.id:
            break
        default:
            XCTFail("The action should select the space.")
        }
    }
    
    func testSelectingUnjoinedSpace() async throws {
        setupViewModel()
        
        let selectedSpace = try XCTUnwrap(mockSpaceRooms.first { $0.isSpace && $0.state != .joined }, "There should be a space to select.")
        let deferred = deferFulfillment(viewModel.actionsPublisher) { _ in true }
        viewModel.context.send(viewAction: .spaceAction(.select(selectedSpace)))
        let action = try await deferred.fulfill()
        
        switch action {
        case .selectUnjoinedSpace(let spaceServiceRoom) where spaceServiceRoom.id == selectedSpace.id:
            break
        default:
            XCTFail("The action should select the space.")
        }
    }
    
    func testSelectingRoom() async throws {
        setupViewModel()
        
        let selectedRoom = try XCTUnwrap(mockSpaceRooms.first { !$0.isSpace }, "There should be a room to select.")
        let deferred = deferFulfillment(viewModel.actionsPublisher) { _ in true }
        viewModel.context.send(viewAction: .spaceAction(.select(selectedRoom)))
        let action = try await deferred.fulfill()
        
        switch action {
        case .selectRoom(let roomID) where roomID == selectedRoom.id:
            break
        default:
            XCTFail("The action should select the room.")
        }
    }
    
    func testJoiningSpace() async throws {
        setupViewModel()
        
        let selectedSpace = try XCTUnwrap(mockSpaceRooms.first { $0.isSpace && $0.state != .joined }, "There should be a space to select.")
        
        let expectation = XCTestExpectation(description: "Join room")
        clientProxy.joinRoomViaClosure = { _, _ in
            expectation.fulfill()
            return .success(())
        }
        let deferredState = deferFulfillment(viewModel.context.observe(\.viewState.joiningRoomIDs), transitionValues: [[selectedSpace.id], []])
        
        viewModel.context.send(viewAction: .spaceAction(.join(selectedSpace)))
        
        await fulfillment(of: [expectation])
        try await deferredState.fulfill()
    }
    
    func testJoiningRoom() async throws {
        setupViewModel()
        
        let selectedRoom = try XCTUnwrap(mockSpaceRooms.first { !$0.isSpace }, "There should be a room to select.")
        
        let expectation = XCTestExpectation(description: "Join room")
        clientProxy.joinRoomViaClosure = { _, _ in
            expectation.fulfill()
            return .success(())
        }
        let deferredState = deferFulfillment(viewModel.context.observe(\.viewState.joiningRoomIDs), transitionValues: [[selectedRoom.id], []])
        
        viewModel.context.send(viewAction: .spaceAction(.join(selectedRoom)))
        
        await fulfillment(of: [expectation])
        try await deferredState.fulfill()
    }
    
    func testManageRoomsWithoutRemoving() throws {
        setupViewModel(initialSpaceRooms: mockSpaceRooms)
        XCTAssertEqual(context.viewState.editMode, .inactive)
        XCTAssertTrue(context.viewState.editModeSelectedIDs.isEmpty)
        XCTAssertTrue(context.viewState.visibleRooms.contains { $0.isSpace })
        
        context.send(viewAction: .manageChildren)
        XCTAssertEqual(context.viewState.editMode, .transient, "Managing rooms should enable edit mode.")
        XCTAssertTrue(context.viewState.editModeSelectedIDs.isEmpty, "No rooms should be selected to begin with.")
        XCTAssertFalse(context.viewState.visibleRooms.contains { $0.isSpace }, "Spaces should be filtered out when managing rooms.")
        
        let selectedRoom = try XCTUnwrap(mockSpaceRooms.first { !$0.isSpace }, "There should be a room to select.")
        XCTAssertFalse(context.viewState.isSpaceIDSelected(selectedRoom.id))
        context.send(viewAction: .spaceAction(.select(selectedRoom)))
        XCTAssertEqual(context.viewState.editModeSelectedIDs.count, 1, "The selected room should be included.")
        XCTAssertTrue(context.viewState.isSpaceIDSelected(selectedRoom.id), "The room should be selected.")
        
        context.send(viewAction: .finishManagingChildren)
        XCTAssertEqual(context.viewState.editMode, .inactive, "Cancelling should disable edit mode.")
        XCTAssertTrue(context.viewState.editModeSelectedIDs.isEmpty, "Cancelling should clear all selected rooms.")
        XCTAssertTrue(context.viewState.visibleRooms.contains { $0.isSpace }, "Cancelling should restore the hidden spaces.")
        
        XCTAssertFalse(spaceServiceProxy.removeChildFromCalled, "There should be no attempt to remove children when cancelling.")
    }
    
    func testManageRoomsRemovingChildren() async throws {
        setupViewModel(initialSpaceRooms: mockSpaceRooms)
        XCTAssertEqual(context.viewState.editMode, .inactive)
        XCTAssertTrue(context.viewState.editModeSelectedIDs.isEmpty)
        XCTAssertTrue(context.viewState.visibleRooms.contains { $0.isSpace })
        
        context.send(viewAction: .manageChildren)
        XCTAssertEqual(context.viewState.editMode, .transient, "Managing rooms should enable edit mode.")
        XCTAssertTrue(context.viewState.editModeSelectedIDs.isEmpty, "No rooms should be selected to begin with.")
        XCTAssertFalse(context.viewState.visibleRooms.contains { $0.isSpace }, "Spaces should be filtered out when managing rooms.")
        
        let firstRoom = try XCTUnwrap(mockSpaceRooms.first { !$0.isSpace }, "There should be a room to select.")
        let lastRoom = try XCTUnwrap(mockSpaceRooms.last { !$0.isSpace }, "There should be a room to select.")
        XCTAssertNotEqual(firstRoom.id, lastRoom.id, "There should be more than one room in the list.")
        context.send(viewAction: .spaceAction(.select(firstRoom)))
        context.send(viewAction: .spaceAction(.select(lastRoom)))
        XCTAssertEqual(context.viewState.editModeSelectedIDs.count, 2, "The selected rooms should be included.")
        
        context.send(viewAction: .removeSelectedChildren)
        XCTAssertTrue(context.isPresentingRemoveChildrenConfirmation, "A confirmation prompt should be shown before removing children.")
        XCTAssertFalse(spaceServiceProxy.removeChildFromCalled, "There should be no attempt to remove children before confirming.")
        
        let deferred = deferFulfillment(context.observe(\.viewState.editMode)) { $0 == .inactive }
        context.send(viewAction: .confirmRemoveSelectedChildren)
        try await deferred.fulfill()
        XCTAssertFalse(context.isPresentingRemoveChildrenConfirmation, "Confirming should dismiss the confirmation prompt.")
        XCTAssertEqual(context.viewState.editMode, .inactive, "Confirming should disable edit mode when done.")
        XCTAssertTrue(context.viewState.editModeSelectedIDs.isEmpty, "Confirming should clear all selected rooms when done.")
        XCTAssertTrue(context.viewState.visibleRooms.contains { $0.isSpace }, "Confirming should restore the hidden spaces when done.")
        
        XCTAssertEqual(spaceServiceProxy.removeChildFromCallsCount, 2, "Each selected room should have been removed.")
        XCTAssertTrue(spaceRoomListProxy.resetCalled, "The room list should be reset to pick up the changes.")
    }
    
    func testManageRoomsRemovingChildrenWithFailure() async throws {
        setupViewModel(initialSpaceRooms: mockSpaceRooms)
        
        context.send(viewAction: .manageChildren)
        for room in context.viewState.visibleRooms {
            context.send(viewAction: .spaceAction(.select(room)))
        }
        context.send(viewAction: .removeSelectedChildren)
        
        XCTAssertEqual(context.viewState.editMode, .transient, "Managing rooms should enable edit mode.")
        XCTAssertEqual(context.viewState.visibleRooms.count, 3, "There should be 3 rooms to begin with.")
        XCTAssertEqual(context.viewState.editModeSelectedIDs.count, 3, "All of the visible rooms should be selected.")
        XCTAssertTrue(context.isPresentingRemoveChildrenConfirmation, "A confirmation prompt should be shown before removing children.")
        
        let successfulIDs = context.viewState.editModeSelectedIDs.prefix(1)
        spaceServiceProxy.removeChildFromClosure = { childID, _ in
            if successfulIDs.contains(childID) {
                .success(())
            } else {
                .failure(.sdkError(SpaceServiceProxyMockError.generic))
            }
        }
        
        let deferred = deferFulfillment(context.observe(\.viewState.visibleRooms.count)) { $0 == 2 }
        let deferredFailure = deferFailure(context.observe(\.viewState.editMode), timeout: 1) { $0 == .inactive }
        context.send(viewAction: .confirmRemoveSelectedChildren)
        try await deferred.fulfill()
        try await deferredFailure.fulfill()
        
        XCTAssertEqual(context.viewState.editMode, .transient, "The screen should remain in edit mode.")
        XCTAssertEqual(context.viewState.visibleRooms.count, 2, "The removed rooms should no longer be listed for selection.")
        XCTAssertEqual(context.viewState.editModeSelectedIDs.count, 2, "The removed rooms should no longer be selected.")
        
        XCTAssertEqual(spaceServiceProxy.removeChildFromCallsCount, 2, "Each selected room should have been removed.")
        XCTAssertFalse(spaceRoomListProxy.resetCalled, "The room list should be reset to pick up the changes.")
    }
    
    func testLeavingSpace() async throws {
        setupViewModel()
        XCTAssertNil(context.leaveSpaceViewModel)
        
        let deferredHandle = deferFulfillment(context.observe(\.leaveSpaceViewModel)) { $0 != nil }
        context.send(viewAction: .leaveSpace)
        try await deferredHandle.fulfill()
        XCTAssertNotNil(context.leaveSpaceViewModel, "The leave action should show the leave view.")
        
        let leaveSpaceViewModel = try XCTUnwrap(context.leaveSpaceViewModel)
        let handle = try XCTUnwrap(context.leaveSpaceViewModel?.state.leaveHandle)
        let selectedCount = handle.selectedCount
        let firstSelectedRoom = try XCTUnwrap(handle.rooms.first { $0.isSelected })
        XCTAssertGreaterThan(selectedCount, 0, "The leave view should have selected rooms to begin with")
        
        leaveSpaceViewModel.context.send(viewAction: .deselectAll)
        XCTAssertEqual(handle.selectedCount, 0, "Deselecting all should result in no selected rooms.")
        
        leaveSpaceViewModel.context.send(viewAction: .toggleRoom(roomID: firstSelectedRoom.spaceServiceRoom.id))
        XCTAssertEqual(handle.selectedCount, 1, "Toggling a room should result in 1 selected room")
        
        // Confirming the leave should leave the selected room and then the space.
        let deferredAction = deferFulfillment(viewModel.actionsPublisher) { $0.isLeftSpace }
        leaveSpaceViewModel.context.send(viewAction: .confirmLeaveSpace)
        try await deferredAction.fulfill()
        XCTAssertNil(context.leaveSpaceViewModel)
        XCTAssertTrue(rustLeaveHandle.leaveRoomIdsCalled)
        XCTAssertEqual(rustLeaveHandle.leaveRoomIdsReceivedRoomIds,
                       [firstSelectedRoom.spaceServiceRoom.id, spaceRoomListProxy.id],
                       "Confirming the leave should first leave the selected room and then the space.")
    }
    
    // MARK: - Helpers
    
    private func setupViewModel(initialSpaceRooms: [SpaceServiceRoom] = [], paginationResponses: [[SpaceServiceRoom]] = []) {
        spaceRoomListProxy = SpaceRoomListProxyMock(.init(spaceServiceRoom: SpaceServiceRoom.mock(isSpace: true),
                                                          initialSpaceRooms: initialSpaceRooms,
                                                          paginationStateSubject: paginationStateSubject,
                                                          paginationResponses: paginationResponses))
        
        spaceServiceProxy = SpaceServiceProxyMock(.init())
        spaceServiceProxy.spaceRoomListSpaceIDClosure = { [mockSpaceRooms] spaceID in
            guard let spaceServiceRoom = mockSpaceRooms.first(where: { $0.id == spaceID }) else { return .failure(.missingSpace) }
            return .success(SpaceRoomListProxyMock(.init(spaceServiceRoom: spaceServiceRoom)))
        }
        let rustLeaveHandle = LeaveSpaceHandleSDKMock(.init())
        spaceServiceProxy.leaveSpaceSpaceIDClosure = { spaceID in
            .success(LeaveSpaceHandleProxy(spaceID: spaceID, leaveHandle: rustLeaveHandle))
        }
        self.rustLeaveHandle = rustLeaveHandle
        
        clientProxy = ClientProxyMock(.init())
        
        viewModel = SpaceScreenViewModel(spaceRoomListProxy: spaceRoomListProxy,
                                         spaceServiceProxy: spaceServiceProxy,
                                         selectedSpaceRoomPublisher: .init(nil),
                                         userSession: UserSessionMock(.init(clientProxy: clientProxy)),
                                         appSettings: AppSettings(),
                                         userIndicatorController: UserIndicatorControllerMock())
    }
}

private extension SpaceScreenViewModelAction {
    var isLeftSpace: Bool {
        switch self {
        case .leftSpace: true
        default: false
        }
    }
}

//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import XCTest

@testable import ElementX
import MatrixRustSDK

@MainActor
class SpaceScreenViewModelTests: XCTestCase {
    var spaceRoomListProxy: SpaceRoomListProxyMock!
    let mockSpaceRooms = [SpaceRoomProxyProtocol].mockSpaceList
    var clientProxy: ClientProxyMock!
    var paginationStateSubject: CurrentValueSubject<SpaceRoomListPaginationState, Never> = .init(.idle(endReached: true))
    var rustLeaveHandle: LeaveSpaceHandleSDKMock!
    
    var viewModel: SpaceScreenViewModelProtocol!
    
    var context: SpaceScreenViewModelType.Context {
        viewModel.context
    }

    func testInitialState() {
        setupViewModel()
        
        XCTAssertFalse(context.viewState.isPaginating)
        XCTAssertTrue(context.viewState.rooms.isEmpty)
        XCTAssertFalse(spaceRoomListProxy.paginateCalled)
    }
    
    func testSinglePagination() async throws {
        // Given a space screen view model for a space with a single paginations worth of children.
        let response = mockSpaceRooms.prefix(3)
        setupViewModel(paginationResponses: [Array(response)])
        
        XCTAssertFalse(context.viewState.isPaginating)
        XCTAssertTrue(context.viewState.rooms.isEmpty)
        XCTAssertFalse(spaceRoomListProxy.paginateCalled)
        XCTAssertFalse(response.isEmpty, "There should be some test rooms.")
        
        // When the pagination is triggered.
        var deferred = deferFulfillment(spaceRoomListProxy.paginationStatePublisher) { $0 == .loading }
        paginationStateSubject.send(.idle(endReached: false)) // Invert the default to allow paginate to be called.
        try await deferred.fulfill()
        
        // Then the screen should show a paginating indicator.
        XCTAssertTrue(context.viewState.isPaginating)
        XCTAssertEqual(spaceRoomListProxy.paginateCallsCount, 1)
        
        // When waiting for the pagination to finish.
        deferred = deferFulfillment(spaceRoomListProxy.paginationStatePublisher) { $0 == .idle(endReached: true) }
        try await deferred.fulfill()
        
        // Then no more pagination requests should be made the the space rooms should be populated.
        XCTAssertFalse(context.viewState.isPaginating)
        XCTAssertEqual(spaceRoomListProxy.paginateCallsCount, 1)
        XCTAssertEqual(context.viewState.rooms.map(\.id), response.map(\.id))
    }
    
    func testMultiplePaginations() async throws {
        // Given a space screen view model for a space with two distinct paginations worth of children.
        let response1 = mockSpaceRooms.prefix(3)
        let response2 = mockSpaceRooms.suffix(mockSpaceRooms.count - 3)
        setupViewModel(paginationResponses: [Array(response1), Array(response2)])
        
        XCTAssertFalse(context.viewState.isPaginating)
        XCTAssertTrue(context.viewState.rooms.isEmpty)
        XCTAssertFalse(spaceRoomListProxy.paginateCalled)
        XCTAssertFalse(response1.isEmpty, "There should be some test rooms.")
        XCTAssertFalse(response2.isEmpty, "There should be more test rooms.")
        
        // When the pagination is triggered.
        let deferredIsPaginating = deferFulfillment(context.observe(\.viewState.isPaginating), transitionValues: [true, false, true, false])
        let deferredState = deferFulfillment(spaceRoomListProxy.paginationStatePublisher, keyPath: \.self, transitionValues: [.loading,
                                                                                                                              .idle(endReached: false),
                                                                                                                              .loading,
                                                                                                                              .idle(endReached: true)])
        paginationStateSubject.send(.idle(endReached: false)) // Invert the default to allow paginate to be called.
        
        // Then the screen should show 2 distinct paginations and finish up with all of the rooms visible.
        try await deferredIsPaginating.fulfill()
        try await deferredState.fulfill()
        
        XCTAssertFalse(context.viewState.isPaginating)
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
        case .selectUnjoinedSpace(let spaceRoomProxy) where spaceRoomProxy.id == selectedSpace.id:
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
    
    func testLeavingSpace() async throws {
        setupViewModel()
        XCTAssertNil(context.leaveHandle)
        
        let deferredHandle = deferFulfillment(context.observe(\.leaveHandle)) { $0 != nil }
        context.send(viewAction: .leaveSpace)
        try await deferredHandle.fulfill()
        XCTAssertNotNil(context.leaveHandle, "The leave action should show the leave view.")
        
        let handle = try XCTUnwrap(context.leaveHandle)
        let selectedCount = handle.selectedCount
        let firstSelectedRoom = try XCTUnwrap(handle.rooms.first { $0.isSelected })
        XCTAssertGreaterThan(selectedCount, 0, "The leave view should have selected rooms to begin with")
        
        context.send(viewAction: .deselectAllLeaveRoomDetails)
        XCTAssertEqual(handle.selectedCount, 0, "Deselecting all should result in no selected rooms.")
        
        context.send(viewAction: .toggleLeaveSpaceRoomDetails(id: firstSelectedRoom.spaceRoomProxy.id))
        XCTAssertEqual(handle.selectedCount, 1, "Toggling a room should result in 1 selected room")
        
        // Confirming the leave should leave the selected room and then the space.
        let deferredAction = deferFulfillment(viewModel.actionsPublisher) { $0.isLeftSpace }
        context.send(viewAction: .confirmLeaveSpace)
        try await deferredAction.fulfill()
        XCTAssertNil(context.leaveHandle)
        XCTAssertTrue(rustLeaveHandle.leaveRoomIdsCalled)
        XCTAssertEqual(rustLeaveHandle.leaveRoomIdsReceivedRoomIds,
                       [firstSelectedRoom.spaceRoomProxy.id, spaceRoomListProxy.id],
                       "Confirming the leave should first leave the selected room and then the space.")
    }
    
    // MARK: - Helpers
    
    private func setupViewModel(paginationResponses: [[SpaceRoomProxyProtocol]] = []) {
        spaceRoomListProxy = SpaceRoomListProxyMock(.init(spaceRoomProxy: SpaceRoomProxyMock(.init(isSpace: true)),
                                                          paginationStateSubject: paginationStateSubject,
                                                          paginationResponses: paginationResponses))
        
        let spaceServiceProxy = SpaceServiceProxyMock(.init())
        spaceServiceProxy.spaceRoomListSpaceIDClosure = { [mockSpaceRooms] spaceID in
            guard let spaceRoomProxy = mockSpaceRooms.first(where: { $0.id == spaceID }) else { return .failure(.missingSpace) }
            return .success(SpaceRoomListProxyMock(.init(spaceRoomProxy: spaceRoomProxy)))
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

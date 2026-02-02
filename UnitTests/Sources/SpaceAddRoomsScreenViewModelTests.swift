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
class SpaceAddRoomsScreenViewModelTests: XCTestCase {
    var spaceRoomListProxy: SpaceRoomListProxyMock!
    var spaceServiceProxy: SpaceServiceProxyMock!
    
    var viewModel: SpaceAddRoomsScreenViewModelProtocol!
    var context: SpaceAddRoomsScreenViewModelType.Context {
        viewModel.context
    }
    
    func testAddingChildRoom() async throws {
        setupViewModel()
        
        var deferred = deferFulfillment(context.observe(\.viewState.roomsSection),
                                        message: "The screen should start with some suggestions.") { section in
            section.type == .suggestions && !section.rooms.isEmpty
        }
        try await deferred.fulfill()
        
        deferred = deferFulfillment(context.observe(\.viewState.roomsSection),
                                    message: "The screen should show search results when there's a query.") { section in
            section.type == .searchResults && !section.rooms.isEmpty
        }
        context.searchQuery = "Foundation"
        context.send(viewAction: .searchQueryChanged)
        try await deferred.fulfill()
        
        let room = try XCTUnwrap(context.viewState.roomsSection.rooms.first)
        context.send(viewAction: .toggleRoom(room))
        XCTAssertTrue(context.viewState.selectedRooms.contains(room), "The selected room should be shown.")
        
        let deferredAction = deferFulfillment(viewModel.actions) { $0 == .dismiss }
        context.send(viewAction: .save)
        
        try await deferredAction.fulfill()
        
        XCTAssertTrue(spaceServiceProxy.addChildToCalled, "The room should have been added to the space.")
        XCTAssertTrue(spaceRoomListProxy.resetCalled, "The room list should be reset to pick up the changes.")
    }
    
    func testFailureWithMultipleRoomsSelected() async throws {
        // Given a view model with 4 selected rooms.
        setupViewModel()
        
        var deferred = deferFulfillment(context.observe(\.viewState.roomsSection),
                                        message: "There should be 4 search results.") { section in
            section.type == .searchResults && section.rooms.count == 4
        }
        context.searchQuery = "f"
        context.send(viewAction: .searchQueryChanged)
        try await deferred.fulfill()
        
        for room in context.viewState.roomsSection.rooms {
            context.send(viewAction: .toggleRoom(room))
        }
        XCTAssertEqual(context.viewState.selectedRooms.count, 4, "All of the rooms should be selected.")
        
        // When there's a failure half way through saving.
        let successfulIDs = context.viewState.roomsSection.rooms.map(\.id).prefix(2)
        spaceServiceProxy.addChildToClosure = { childID, _ in
            if successfulIDs.contains(childID) {
                .success(())
            } else {
                .failure(.sdkError(SpaceServiceProxyMockError.generic))
            }
        }
        
        deferred = deferFulfillment(context.observe(\.viewState.roomsSection),
                                    message: "The search results should update.") { section in
            section.type == .searchResults && section.rooms.count == 2
        }
        context.send(viewAction: .save)
        try await deferred.fulfill()
        
        // Then the screen should be updated to only show the rooms that still need to be added.
        XCTAssertEqual(spaceServiceProxy.addChildToCallsCount, 3, "The remaining calls to the service should stop after a failure.")
        XCTAssertFalse(context.viewState.selectedRooms.contains { successfulIDs.contains($0.id) },
                       "The added rooms should no longer show as selected.")
        XCTAssertFalse(context.viewState.roomsSection.rooms.contains { successfulIDs.contains($0.id) },
                       "The added rooms should no longer be listed for selection.")
    }
    
    func setupViewModel() {
        let summaryProvider = RoomSummaryProviderMock(.init(state: .loaded(.mockRooms)))
        spaceRoomListProxy = SpaceRoomListProxyMock(.init(spaceServiceRoom: SpaceServiceRoom.mock(isSpace: true)))
        
        let clientProxy = ClientProxyMock(.init())
        clientProxy.recentlyVisitedRoomsFilterReturnValue = .init(repeating: JoinedRoomProxyMock(.init()), count: 5)
        spaceServiceProxy = clientProxy.underlyingSpaceService as? SpaceServiceProxyMock
        
        viewModel = SpaceAddRoomsScreenViewModel(spaceRoomListProxy: spaceRoomListProxy,
                                                 userSession: UserSessionMock(.init(clientProxy: clientProxy)),
                                                 roomSummaryProvider: summaryProvider,
                                                 userIndicatorController: UserIndicatorControllerMock())
    }
}

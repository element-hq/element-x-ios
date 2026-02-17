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
struct SpaceAddRoomsScreenViewModelTests {
    @MainActor
    private struct TestSetup {
        var spaceRoomListProxy: SpaceRoomListProxyMock
        var spaceServiceProxy: SpaceServiceProxyMock
        var viewModel: SpaceAddRoomsScreenViewModelProtocol
        
        var context: SpaceAddRoomsScreenViewModelType.Context {
            viewModel.context
        }
        
        init() {
            let summaryProvider = RoomSummaryProviderMock(.init(state: .loaded(.mockRooms)))
            spaceRoomListProxy = SpaceRoomListProxyMock(.init(spaceServiceRoom: SpaceServiceRoom.mock(isSpace: true)))
            
            let clientProxy = ClientProxyMock(.init())
            clientProxy.recentlyVisitedRoomsFilterReturnValue = .init(repeating: JoinedRoomProxyMock(.init()), count: 5)
            spaceServiceProxy = clientProxy.underlyingSpaceService as! SpaceServiceProxyMock
            
            viewModel = SpaceAddRoomsScreenViewModel(spaceRoomListProxy: spaceRoomListProxy,
                                                     userSession: UserSessionMock(.init(clientProxy: clientProxy)),
                                                     roomSummaryProvider: summaryProvider,
                                                     userIndicatorController: UserIndicatorControllerMock())
        }
    }
    
    @Test
    func addingChildRoom() async throws {
        var testSetup = TestSetup()
        
        var deferred = deferFulfillment(testSetup.context.observe(\.viewState.roomsSection),
                                        message: "The screen should start with some suggestions.") { section in
            section.type == .suggestions && !section.rooms.isEmpty
        }
        try await deferred.fulfill()
        
        deferred = deferFulfillment(testSetup.context.observe(\.viewState.roomsSection),
                                    message: "The screen should show search results when there's a query.") { section in
            section.type == .searchResults && !section.rooms.isEmpty
        }
        testSetup.context.searchQuery = "Foundation"
        testSetup.context.send(viewAction: .searchQueryChanged)
        try await deferred.fulfill()
        
        guard let room = testSetup.context.viewState.roomsSection.rooms.first else {
            Issue.record("Expected a room in the section")
            return
        }
        testSetup.context.send(viewAction: .toggleRoom(room))
        #expect(testSetup.context.viewState.selectedRooms.contains(room), "The selected room should be shown.")
        
        let deferredAction = deferFulfillment(testSetup.viewModel.actions) { $0 == .dismiss }
        testSetup.context.send(viewAction: .save)
        
        try await deferredAction.fulfill()
        
        #expect(testSetup.spaceServiceProxy.addChildToCalled, "The room should have been added to the space.")
        #expect(testSetup.spaceRoomListProxy.resetCalled, "The room list should be reset to pick up the changes.")
    }
    
    @Test
    func failureWithMultipleRoomsSelected() async throws {
        // Given a view model with 4 selected rooms.
        var testSetup = TestSetup()
        
        var deferred = deferFulfillment(testSetup.context.observe(\.viewState.roomsSection),
                                        message: "There should be 4 search results.") { section in
            section.type == .searchResults && section.rooms.count == 4
        }
        testSetup.context.searchQuery = "f"
        testSetup.context.send(viewAction: .searchQueryChanged)
        try await deferred.fulfill()
        
        for room in testSetup.context.viewState.roomsSection.rooms {
            testSetup.context.send(viewAction: .toggleRoom(room))
        }
        #expect(testSetup.context.viewState.selectedRooms.count == 4, "All of the rooms should be selected.")
        
        // When there's a failure half way through saving.
        let successfulIDs = testSetup.context.viewState.roomsSection.rooms.map(\.id).prefix(2)
        testSetup.spaceServiceProxy.addChildToClosure = { childID, _ in
            if successfulIDs.contains(childID) {
                .success(())
            } else {
                .failure(.sdkError(SpaceServiceProxyMockError.generic))
            }
        }
        
        deferred = deferFulfillment(testSetup.context.observe(\.viewState.roomsSection),
                                    message: "The search results should update.") { section in
            section.type == .searchResults && section.rooms.count == 2
        }
        testSetup.context.send(viewAction: .save)
        try await deferred.fulfill()
        
        // Then the screen should be updated to only show the rooms that still need to be added.
        #expect(testSetup.spaceServiceProxy.addChildToCallsCount == 3, "The remaining calls to the service should stop after a failure.")
        #expect(!testSetup.context.viewState.selectedRooms.contains { successfulIDs.contains($0.id) },
                "The added rooms should no longer show as selected.")
        #expect(!testSetup.context.viewState.roomsSection.rooms.contains { successfulIDs.contains($0.id) },
                "The added rooms should no longer be listed for selection.")
    }
}

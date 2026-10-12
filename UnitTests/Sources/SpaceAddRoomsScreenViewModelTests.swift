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
struct SpaceAddRoomsScreenViewModelTests {
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
        clientProxy.recentlyVisitedRoomsFilterReturnValue = (0..<5).map { JoinedRoomProxyMock(.init(id: "suggestion-\($0)")) }
        spaceServiceProxy = clientProxy.spaceService as? SpaceServiceProxyMock ?? SpaceServiceProxyMock(.init())
        
        viewModel = SpaceAddRoomsScreenViewModel(spaceRoomListProxy: spaceRoomListProxy,
                                                 userSession: UserSessionMock(.init(clientProxy: clientProxy)),
                                                 roomSummaryProvider: summaryProvider,
                                                 userIndicatorController: UserIndicatorControllerMock())
    }
    
    @Test
    func addingChildRoom() async throws {
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
        
        let room = try #require(context.viewState.roomsSection.rooms.first, "Expected a room in the section")
        context.send(viewAction: .toggleRoom(room))
        #expect(context.viewState.selectedRooms.contains(room), "The selected room should be shown.")
        
        let deferredAction = deferFulfillment(viewModel.actions) { $0 == .dismiss }
        context.send(viewAction: .save)
        
        try await deferredAction.fulfill()
        
        #expect(spaceServiceProxy.addChildToCalled, "The room should have been added to the space.")
        #expect(spaceRoomListProxy.resetCalled, "The room list should be reset to pick up the changes.")
    }
    
    @Test(arguments: [true, false])
    func failureWithMultipleRoomsSelected(search: Bool) async throws {
        let initialCount = search ? 4 : 5
        let sectionType: SpaceAddRoomsScreenViewState.Section.SectionType = search ? .searchResults : .suggestions
        // Given a view model with several selected rooms.
        var deferred = deferFulfillment(context.observe(\.viewState.roomsSection),
                                        message: "The candidate rooms should be shown.") { section in
            section.type == sectionType && section.rooms.count == initialCount
        }
        context.searchQuery = search ? "f" : ""
        context.send(viewAction: .searchQueryChanged)
        try await deferred.fulfill()
        
        for room in context.viewState.roomsSection.rooms {
            context.send(viewAction: .toggleRoom(room))
        }
        #expect(context.viewState.selectedRooms.count == initialCount, "All of the rooms should be selected.")
        
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
                                    message: "The candidates should update after a partial save.") { section in
            section.type == sectionType && section.rooms.count == initialCount - 2
        }
        context.send(viewAction: .save)
        try await deferred.fulfill()
        
        // Then the screen should be updated to only show the rooms that still need to be added.
        #expect(spaceServiceProxy.addChildToCallsCount == 3, "The remaining calls to the service should stop after a failure.")
        #expect(!context.viewState.selectedRooms.contains { successfulIDs.contains($0.id) },
                "The added rooms should no longer show as selected.")
        #expect(!context.viewState.roomsSection.rooms.contains { successfulIDs.contains($0.id) },
                "The added rooms should no longer be listed for selection.")
    }
    
    @Test(arguments: [true, false])
    func spaceMembershipUpdatesCandidates(search: Bool) async throws {
        let summaries = [RoomSummary.mock(id: "first", name: "First room"),
                         .mock(id: "existing", name: "Existing room"),
                         .mock(id: "second", name: "Second room")]
        let summariesSubject = CurrentValueSubject<[RoomSummary], Never>(summaries)
        let summaryProvider = RoomSummaryProviderMock(.init(state: .loaded([])))
        summaryProvider.roomListPublisher = summariesSubject.asCurrentValuePublisher()
        let spaceRoomsSubject = CurrentValueSubject<[SpaceServiceRoom], Never>([.mock(id: "existing", isSpace: false)])
        spaceRoomListProxy.spaceRoomsPublisher = spaceRoomsSubject.asCurrentValuePublisher()
        let clientProxy = ClientProxyMock(.init())
        let recentRooms = summaries.map { JoinedRoomProxyMock(.init(id: $0.id)) }
        clientProxy.recentlyVisitedRoomsFilterClosure = { filter in
            var rooms: [JoinedRoomProxyProtocol] = []
            for room in recentRooms where await filter(room) {
                rooms.append(room)
            }
            return rooms
        }
        let viewModel = SpaceAddRoomsScreenViewModel(spaceRoomListProxy: spaceRoomListProxy,
                                                     userSession: UserSessionMock(.init(clientProxy: clientProxy)),
                                                     roomSummaryProvider: summaryProvider,
                                                     userIndicatorController: UserIndicatorControllerMock())
        let context = viewModel.context
        context.searchQuery = search ? "room" : ""
        var deferred = deferFulfillment(context.observe(\.viewState.roomsSection)) {
            $0.rooms.map(\.id) == ["first", "second"]
        }
        try await deferred.fulfill()
        
        deferred = deferFulfillment(context.observe(\.viewState.roomsSection)) {
            $0.rooms.map(\.id) == ["second"]
        }
        spaceRoomsSubject.send([.mock(id: "existing", isSpace: false), .mock(id: "first", isSpace: false)])
        try await deferred.fulfill()
        
        // An empty snapshot during reload must not make known children selectable again.
        deferred = deferFulfillment(context.observe(\.viewState.roomsSection)) {
            $0.type == .searchResults && $0.rooms.map(\.id) == ["second", "third"]
        }
        spaceRoomsSubject.send([])
        context.searchQuery = "room"
        summariesSubject.send(summaries + [.mock(id: "third", name: "Third room")])
        try await deferred.fulfill()
    }
}

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
class SpaceAddRoomsScreenViewModelTests: XCTestCase {
    var viewModel: SpaceAddRoomsScreenViewModelProtocol!
    var context: SpaceAddRoomsScreenViewModelType.Context { viewModel.context }
    
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
    }
    
    func setupViewModel() {
        let summaryProvider = RoomSummaryProviderMock(.init(state: .loaded(.mockRooms)))
        let spaceRoomListProxy = SpaceRoomListProxyMock(.init(spaceServiceRoom: SpaceServiceRoomMock(.init(isSpace: true))))
        
        let clientProxy = ClientProxyMock(.init())
        clientProxy.recentlyVisitedRoomsFilterReturnValue = .init(repeating: JoinedRoomProxyMock(.init()), count: 5)
        
        viewModel = SpaceAddRoomsScreenViewModel(spaceRoomListProxy: spaceRoomListProxy,
                                                 userSession: UserSessionMock(.init(clientProxy: clientProxy)),
                                                 roomSummaryProvider: summaryProvider,
                                                 userIndicatorController: UserIndicatorControllerMock())
    }
}

//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Testing

struct RoomSelectionScreenViewModelTests {
    let viewModel: RoomSelectionScreenViewModelProtocol
    let context: RoomSelectionScreenViewModelType.Context
    
    init() {
        viewModel = RoomSelectionScreenViewModel(userSession: UserSessionMock(.init()),
                                                 roomSummaryProvider: RoomSummaryProviderMock(.init(state: .loaded(.mockRooms))))
        context = viewModel.context
    }
    
    @Test("Upgraded rooms aren't listed")
    func upgradedRoomsAreNotListed() {
        #expect(!context.viewState.rooms.isEmpty)
        #expect(!context.viewState.rooms.contains { $0.id == "7" }, "Upgraded rooms shouldn't be shown")
    }
    
    @Test("Searching for something no room matches shows the no results state")
    func noResults() async throws {
        let deferred = deferFulfillment(context.$viewState) { $0.showsNoResults }
        context.searchQuery = "Nothing matches this"
        try await deferred.fulfill()
        #expect(context.viewState.isSearching)
        #expect(context.viewState.rooms.isEmpty)
    }
}

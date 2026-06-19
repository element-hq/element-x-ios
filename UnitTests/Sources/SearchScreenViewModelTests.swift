//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Testing

@MainActor
struct SearchScreenViewModelTests {
    let viewModel: SearchScreenViewModelProtocol
    var context: SearchScreenViewModelType.Context {
        viewModel.context
    }
    
    init() {
        viewModel = SearchScreenViewModel(roomSummaryProvider: RoomSummaryProviderMock(.init(state: .loaded(.mockRooms))),
                                          mediaProvider: MediaProviderMock(.init()))
    }
    
    @Test
    func searching() async throws {
        let deferred = deferFulfillment(context.observe(\.viewState.rooms)) { $0.count == 1 }
        context.searchQuery = "Second"
        try await deferred.fulfill()
    }
    
    @Test
    func roomSelection() async throws {
        let deferred = deferFulfillment(viewModel.actionsPublisher) { action in
            switch action {
            case .presentRoom(let roomID):
                roomID == "2"
            }
        }
        
        context.send(viewAction: .selectRoom(roomID: "2"))
        
        try await deferred.fulfill()
    }
}

//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
@testable import ElementX
import Testing

@MainActor
struct SearchScreenViewModelTests {
    let viewModel: SearchScreenViewModelProtocol
    var context: SearchScreenViewModelType.Context {
        viewModel.context
    }
    
    init() {
        let searchService = SearchServiceProxyMock()
        searchService.underlyingResultsPublisher = CurrentValueSubject<[SearchServiceResult], Never>([]).asCurrentValuePublisher()
        searchService.underlyingPaginationStatePublisher = CurrentValueSubject(.idle(endReached: true)).asCurrentValuePublisher()
        searchService.setQueryReturnValue = .success(())
        
        let clientProxy = ClientProxyMock(.init())
        clientProxy.searchService = searchService
        
        viewModel = SearchScreenViewModel(roomSummaryProvider: RoomSummaryProviderMock(.init(state: .loaded(.mockRooms))),
                                          clientProxy: clientProxy,
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
            case .presentRoom(let roomID, _):
                roomID == "2"
            case .cancel:
                false
            }
        }
        
        context.send(viewAction: .selectRoom(roomID: "2"))
        
        try await deferred.fulfill()
    }
    
    @Test
    func cancel() async throws {
        let deferred = deferFulfillment(viewModel.actionsPublisher) { action in
            switch action {
            case .cancel:
                true
            default:
                false
            }
        }
        
        context.send(viewAction: .cancel)
        
        try await deferred.fulfill()
    }
}

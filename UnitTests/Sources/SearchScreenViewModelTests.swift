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
    let searchService: SearchServiceProxyMock
    let userIndicatorController: UserIndicatorControllerMock
    /// Fires with the query each time the (async, debounced) message search runs.
    let setQuerySubject = PassthroughSubject<String, Never>()
    /// Fires each time an indicator is submitted.
    let submitIndicatorSubject = PassthroughSubject<Void, Never>()
    
    var context: SearchScreenViewModelType.Context {
        viewModel.context
    }
    
    init() {
        searchService = SearchServiceProxyMock()
        searchService.underlyingResultsPublisher = CurrentValueSubject<[SearchServiceResult], Never>([]).asCurrentValuePublisher()
        searchService.underlyingPaginationStatePublisher = CurrentValueSubject(.idle(endReached: true)).asCurrentValuePublisher()
        searchService.setQueryClosure = { [setQuerySubject] query in
            setQuerySubject.send(query)
            return .success(())
        }
        
        userIndicatorController = UserIndicatorControllerMock()
        userIndicatorController.submitIndicatorDelayClosure = { [submitIndicatorSubject] _, _ in
            submitIndicatorSubject.send(())
        }
        
        let clientProxy = ClientProxyMock(.init())
        clientProxy.searchService = searchService
        
        viewModel = SearchScreenViewModel(roomSummaryProvider: RoomSummaryProviderMock(.init(state: .loaded(.mockRooms))),
                                          clientProxy: clientProxy,
                                          mediaProvider: MediaProviderMock(.init()),
                                          userIndicatorController: userIndicatorController)
    }
    
    @Test
    func searching() async throws {
        let deferred = deferFulfillment(context.observe(\.viewState.rooms)) { $0.count == 1 }
        context.searchQuery = "Second"
        try await deferred.fulfill()
        
        // The rooms tab must not trigger the slow message search.
        #expect(!searchService.setQueryCalled)
    }
    
    @Test
    func messageSearch() async throws {
        let deferred = deferFulfillment(setQuerySubject) { $0 == "Foundation" }
        context.searchMode = .messages
        context.searchQuery = "Foundation"
        try await deferred.fulfill()
        
        #expect(searchService.setQueryReceivedQuery == "Foundation")
    }
    
    @Test
    func messageSearchFailureShowsErrorIndicator() async throws {
        searchService.setQueryClosure = { _ in .failure(.sdkError(SearchScreenViewModelTestsError.failed)) }
        
        let deferred = deferFulfillment(submitIndicatorSubject) { _ in true }
        context.searchMode = .messages
        context.searchQuery = "Foundation"
        try await deferred.fulfill()
        
        #expect(userIndicatorController.submitIndicatorDelayCalled)
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

private enum SearchScreenViewModelTestsError: Error {
    case failed
}

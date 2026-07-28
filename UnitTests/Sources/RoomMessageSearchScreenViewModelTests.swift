//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
@testable import ElementX
import Testing

@MainActor
struct RoomMessageSearchScreenViewModelTests {
    let searchService = SearchServiceProxyMock()
    let resultsSubject = CurrentValueSubject<[SearchServiceResult], Never>([])
    let paginationStateSubject = CurrentValueSubject<SearchServicePaginationState, Never>(.idle(endReached: false))
    let viewModel: RoomMessageSearchScreenViewModel
    var context: RoomMessageSearchScreenViewModelType.Context {
        viewModel.context
    }
    
    init() {
        searchService.underlyingResultsPublisher = resultsSubject.asCurrentValuePublisher()
        searchService.underlyingPaginationStatePublisher = paginationStateSubject.asCurrentValuePublisher()
        searchService.setQueryReturnValue = .success(())
        searchService.paginateReturnValue = .success(())
        
        viewModel = RoomMessageSearchScreenViewModel(searchService: searchService,
                                                     userID: "@me:example.org",
                                                     mediaProvider: MediaProviderMock(.init()))
    }
    
    @Test func typingMarksSearchingBeforeTheDebounceElapses() async throws {
        let deferred = deferFulfillment(context.observe(\.viewState.isSearching)) { $0 }
        context.searchQuery = "hello"
        try await deferred.fulfill()
        // The debounce hasn't elapsed: nothing has reached the service yet.
        #expect(!searchService.setQueryCalled)
    }
    
    @Test func debouncedQueryReachesTheService() async throws {
        let deferred = deferFulfillment(context.observe(\.viewState.isSearching), transitionValues: [true, false])
        context.searchQuery = "hello"
        try await deferred.fulfill()
        #expect(searchService.setQueryReceivedInvocations == ["hello"])
    }
    
    @Test func aFailedQueryIsNotPresentedAsEmpty() async throws {
        searchService.setQueryReturnValue = .failure(.sdkError(SearchServiceMockError.generic))
        let deferred = deferFulfillment(context.observe(\.viewState.hasError)) { $0 }
        context.searchQuery = "hello"
        try await deferred.fulfill()
        #expect(!context.viewState.displayEmptyState)
    }
    
    @Test func clearingTheQueryReturnsToTheInitialState() async throws {
        let searched = deferFulfillment(context.observe(\.viewState.isSearching), transitionValues: [true, false])
        context.searchQuery = "hello"
        try await searched.fulfill()
        
        // Deliver a result for the active query so the "returns to empty" check isn't vacuous.
        resultsSubject.send([.fixtureResult])
        let populated = deferFulfillment(context.observe(\.viewState.results)) { !$0.isEmpty }
        try await populated.fulfill()
        
        // Clearing the query drops the results and returns to the initial state.
        let cleared = deferFulfillment(context.observe(\.viewState.results)) { $0.isEmpty }
        context.searchQuery = ""
        try await cleared.fulfill()
        #expect(context.viewState.displayInitialState)
    }
    
    @Test func roomScopedWalkPaginatesWhileEmpty() async throws {
        // Script the service: two empty pages, then the end.
        var pages = 0
        searchService.paginateClosure = { [paginationStateSubject] in
            pages += 1
            paginationStateSubject.send(.idle(endReached: pages >= 2))
            return .success(())
        }
        let deferred = deferFulfillment(context.observe(\.viewState.endReached)) { $0 }
        context.searchQuery = "hello"
        try await deferred.fulfill()
        #expect(searchService.paginateCallsCount == 2)
        #expect(context.viewState.displayEmptyState)
    }
    
    @Test func walkStopsOnceTheRoomHasAResult() async throws {
        searchService.paginateClosure = { [resultsSubject, paginationStateSubject] in
            resultsSubject.send([.fixtureResult])
            paginationStateSubject.send(.idle(endReached: false))
            return .success(())
        }
        let deferred = deferFulfillment(context.observe(\.viewState.results)) { !$0.isEmpty }
        context.searchQuery = "hello"
        try await deferred.fulfill()
        // Give the walk a beat to (wrongly) continue, then assert it pulled exactly one page.
        try await Task.sleep(for: .milliseconds(100))
        #expect(searchService.paginateCallsCount == 1)
    }
    
    @Test func listEndVisibilityPullsAnotherPage() async throws {
        resultsSubject.send([.fixtureResult])
        let searched = deferFulfillment(context.observe(\.viewState.isSearching), transitionValues: [true, false])
        context.searchQuery = "hello"
        try await searched.fulfill()
        
        searchService.paginateClosure = { [paginationStateSubject] in
            paginationStateSubject.send(.idle(endReached: true))
            return .success(())
        }
        let ended = deferFulfillment(context.observe(\.viewState.endReached)) { $0 }
        context.send(viewAction: .listEndVisible(true))
        try await ended.fulfill()
        #expect(searchService.paginateCallsCount == 1)
    }
    
    @Test func endReachedStopsTheWalk() async throws {
        paginationStateSubject.send(.idle(endReached: true))
        let searched = deferFulfillment(context.observe(\.viewState.isSearching), transitionValues: [true, false])
        context.searchQuery = "hello"
        try await searched.fulfill()
        try await Task.sleep(for: .milliseconds(100))
        #expect(!searchService.paginateCalled)
    }
    
    @Test func aFailedPageStopsTheWalkAndShowsTheError() async throws {
        searchService.paginateClosure = { .failure(.sdkError(SearchServiceMockError.generic)) }
        let deferred = deferFulfillment(context.observe(\.viewState.hasError)) { $0 }
        context.searchQuery = "hello"
        try await deferred.fulfill()
        #expect(searchService.paginateCallsCount == 1)
        #expect(!context.viewState.displayEmptyState)
    }
    
    @Test func selectingAResultPresentsTheEvent() async throws {
        let deferred = deferFulfillment(viewModel.actionsPublisher) { $0 == .presentEvent(eventID: "$event") }
        context.send(viewAction: .selectResult(eventID: "$event"))
        try await deferred.fulfill()
    }
    
    @Test func aNewerQuerySupersedesTheOlderOne() async throws {
        let firstSearched = deferFulfillment(context.observe(\.viewState.isSearching), transitionValues: [true, false])
        context.searchQuery = "one"
        try await firstSearched.fulfill()
        #expect(searchService.setQueryReceivedInvocations == ["one"])
        
        // A second, distinct query supersedes the first and reaches the service after it.
        let secondSearched = deferFulfillment(context.observe(\.viewState.isSearching), transitionValues: [true, false])
        context.searchQuery = "two"
        try await secondSearched.fulfill()
        #expect(searchService.setQueryReceivedInvocations == ["one", "two"])
    }
    
    @Test func aListEndTriggerPullsExactlyOnePage() async throws {
        // With results already present, each list-end trigger loads one page and stops — rather than
        // walking continuously to exhaustion — then waits for the next trigger.
        resultsSubject.send([.fixtureResult])
        let searched = deferFulfillment(context.observe(\.viewState.isSearching), transitionValues: [true, false])
        context.searchQuery = "hello"
        try await searched.fulfill()
        
        searchService.paginateClosure = { [paginationStateSubject] in
            paginationStateSubject.send(.idle(endReached: false))
            return .success(())
        }
        context.send(viewAction: .listEndVisible(true))
        try await Task.sleep(for: .milliseconds(150))
        #expect(searchService.paginateCallsCount == 1)
        
        // Scrolling away from the end does not resume pagination.
        context.send(viewAction: .listEndVisible(false))
        try await Task.sleep(for: .milliseconds(100))
        #expect(searchService.paginateCallsCount == 1)
    }
    
    @Test func aFailedPageKeepsExistingResultsVisible() async throws {
        resultsSubject.send([.fixtureResult])
        let searched = deferFulfillment(context.observe(\.viewState.isSearching), transitionValues: [true, false])
        context.searchQuery = "hello"
        try await searched.fulfill()
        #expect(!context.viewState.results.isEmpty)
        
        // A background page fails after results already loaded — the full-screen error must not
        // preempt the already-visible results.
        searchService.paginateClosure = { .failure(.sdkError(SearchServiceMockError.generic)) }
        let errored = deferFulfillment(context.observe(\.viewState.hasError)) { $0 }
        context.send(viewAction: .listEndVisible(true))
        try await errored.fulfill()
        
        #expect(!context.viewState.results.isEmpty)
        #expect(!context.viewState.displayErrorState)
    }
}

private enum SearchServiceMockError: Error { case generic }

private extension SearchServiceResult {
    static var fixtureResult: SearchServiceResult {
        SearchServiceResult(roomID: "!room:example.org",
                            eventID: "$event",
                            sender: .init(id: "@alice:example.org", displayName: "Alice"),
                            content: .message(.text(.init(body: "A search result"))),
                            timestamp: .now)
    }
}

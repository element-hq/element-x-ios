//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

// AsyncAlgorithms provides `.debounce` on the Observations sequence — the same import the Search
// tab's view model needs for the identical pipeline (SearchScreenViewModel.swift).
import AsyncAlgorithms
import Combine
import SwiftUI

typealias RoomMessageSearchScreenViewModelType = StateStoreViewModelV2<RoomMessageSearchScreenViewState, RoomMessageSearchScreenViewAction>

class RoomMessageSearchScreenViewModel: RoomMessageSearchScreenViewModelType, RoomMessageSearchScreenViewModelProtocol {
    private let searchService: SearchServiceProxyProtocol
    private let userID: String
    
    private var searchQueryObservationTask: Task<Void, Never>?
    private var searchingObservationTask: Task<Void, Never>?
    private var setQueryTask: Task<Void, Never>?
    private var paginationWalkTask: Task<Void, Never>?
    /// Bumped every time a walk starts, so a superseded walk that finishes late can tell it is no
    /// longer the current one and must not clear the shared handle.
    private var walkGeneration = 0
    private var isListEndVisible = false
    
    private let actionsSubject: PassthroughSubject<RoomMessageSearchScreenViewModelAction, Never> = .init()
    var actionsPublisher: AnyPublisher<RoomMessageSearchScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(searchService: SearchServiceProxyProtocol,
         userID: String,
         mediaProvider: MediaProviderProtocol) {
        self.searchService = searchService
        self.userID = userID
        
        super.init(initialViewState: RoomMessageSearchScreenViewState(), mediaProvider: mediaProvider)
        
        searchService.resultsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] results in
                guard let self else { return }
                // A previous query's fetch can complete after the field was cleared; drop it.
                guard !state.bindings.searchQuery.isEmpty else {
                    state.results = []
                    return
                }
                state.results = results.map { RoomMessageSearchResult($0, isOutgoing: $0.sender.id == userID) }
            }
            .store(in: &cancellables)
        
        searchService.paginationStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] paginationState in
                guard let self else { return }
                switch paginationState {
                case .loading:
                    state.isPaginating = true
                    // A fresh page — or a new query, which publishes `.loading` — clears any
                    // `endReached` carried over from a previous, exhausted query. Without this a
                    // query typed after one that hit the end would render blank (neither the
                    // searching spinner nor "no results") for the whole round trip.
                    state.endReached = false
                case .idle(let endReached):
                    state.isPaginating = false
                    state.endReached = endReached
                }
            }
            .store(in: &cancellables)
        
        let debouncedQueryStream = context.observe(\.viewState.bindings.searchQuery)
            .debounce(for: .milliseconds(250))
            .removeDuplicates()
        searchQueryObservationTask = Task { [weak self] in
            for await searchQuery in debouncedQueryStream {
                self?.runQuery(searchQuery)
            }
        }
        
        // Flip `isSearching` on the raw keystroke, ahead of the debounce, so the empty state
        // cannot flash while the first search is still pending. Typing also clears a stale error.
        let rawQueryStream = context.observe(\.viewState.bindings.searchQuery).removeDuplicates()
        searchingObservationTask = Task { [weak self] in
            for await searchQuery in rawQueryStream {
                guard let self else { return }
                state.hasError = false
                state.isSearching = !searchQuery.isEmpty
            }
        }
    }
    
    isolated deinit {
        searchQueryObservationTask?.cancel()
        searchingObservationTask?.cancel()
        setQueryTask?.cancel()
        paginationWalkTask?.cancel()
    }
    
    // MARK: - Public
    
    override func process(viewAction: RoomMessageSearchScreenViewAction) {
        switch viewAction {
        case .selectResult(let eventID):
            actionsSubject.send(.presentEvent(eventID: eventID))
        case .listEndVisible(let isVisible):
            isListEndVisible = isVisible
            if isVisible {
                startPaginationWalkIfNeeded()
            }
        }
    }
    
    // MARK: - Private
    
    private func runQuery(_ searchQuery: String) {
        // Supersede any in-flight query AND the previous query's walk, so a page for the old
        // cursor state cannot overlap the new one (Android cancels its pagination effect by
        // keying it on the query).
        setQueryTask?.cancel()
        paginationWalkTask?.cancel()
        paginationWalkTask = nil
        
        guard !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            state.isSearching = false
            state.results = []
            return
        }
        
        setQueryTask = Task { [weak self] in
            guard let self else { return }
            let result = await searchService.setQuery(searchQuery)
            guard !Task.isCancelled else { return }
            if case .failure = result {
                // A failed query must never be presented as an empty result.
                state.hasError = true
            }
            state.isSearching = false
            startPaginationWalkIfNeeded()
        }
    }
    
    /// Pulls pages one at a time while the room has nothing to show (results are filtered from a
    /// globally ranked set, so an empty room-scoped list over a non-exhausted index means
    /// "keep walking") or while the user is at the end of the list.
    private func startPaginationWalkIfNeeded() {
        guard paginationWalkTask == nil, shouldPaginate else { return }
        
        walkGeneration += 1
        let generation = walkGeneration
        paginationWalkTask = Task { [weak self] in
            // Only clear the shared handle if THIS walk is still the current one. A superseded walk
            // parked in a non-cancellable `paginate()` can finish after a newer walk was assigned;
            // clearing unconditionally would orphan the newer walk and let a duplicate spawn.
            defer {
                if self?.walkGeneration == generation {
                    self?.paginationWalkTask = nil
                }
            }
            while !Task.isCancelled {
                // Await the current-or-next `.idle` BEFORE deciding to pull a page. The order is
                // load-bearing: a fresh subscription to a CurrentValuePublisher replays its
                // current value, and the SDK can still read `.loading` for a moment after
                // `paginate()` returns — so "await idle, then decide, then paginate once" is the
                // race-free sequence. This is exactly the Android presenter's loop shape
                // (MessageSearchPresenter.kt: awaits Idle, then issues one page).
                guard let publisher = self?.searchService.paginationStatePublisher else { return }
                var endReached: Bool?
                for await paginationState in publisher.values {
                    if case .idle(let idleEndReached) = paginationState {
                        endReached = idleEndReached
                        break
                    }
                }
                
                guard let self, !Task.isCancelled, endReached == false, shouldPaginate else { return }
                
                if case .failure = await searchService.paginate() {
                    // A failed page must never be presented as "no results" (Phase 1 made
                    // `paginate()` return a Result for exactly this).
                    state.hasError = true
                    return
                }
                
                // Once the room has results, a walk driven by list-end visibility loads one page per
                // scroll rather than continuously to exhaustion — reset the flag and wait for the next
                // trigger. The empty-room walk keeps going on its own (results-empty) condition.
                if !searchService.resultsPublisher.value.isEmpty {
                    isListEndVisible = false
                }
            }
        }
    }
    
    private var shouldPaginate: Bool {
        guard !state.bindings.searchQuery.isEmpty, !state.isSearching, !state.hasError, !state.endReached else {
            return false
        }
        // Read the proxy's current value rather than `state.results`, which lags on a separate
        // main-queue hop — otherwise the walk can pull an extra page before a just-fetched result
        // has landed in the view state.
        return searchService.resultsPublisher.value.isEmpty || isListEndVisible
    }
}

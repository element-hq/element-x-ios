//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import AsyncAlgorithms
import Combine
import SwiftUI

typealias SearchScreenViewModelType = StateStoreViewModelV2<SearchScreenViewState, SearchScreenViewAction>

class SearchScreenViewModel: SearchScreenViewModelType, SearchScreenViewModelProtocol {
    private let roomSummaryProvider: RoomSummaryProviderProtocol
    private let searchService: SearchServiceProxyProtocol
    private let clientProxy: ClientProxyProtocol
    private var searchQueryObservationTask: Task<Void, Never>?
    private var loadingObservationTask: Task<Void, Never>?
    private var setQueryTask: Task<Void, Never>?
    
    private let actionsSubject: PassthroughSubject<SearchScreenViewModelAction, Never> = .init()
    var actionsPublisher: AnyPublisher<SearchScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(roomSummaryProvider: RoomSummaryProviderProtocol,
         clientProxy: ClientProxyProtocol,
         mediaProvider: MediaProviderProtocol,
         initialSearchQuery: String = "",
         initialSearchMode: SearchScreenMode = .rooms) {
        self.roomSummaryProvider = roomSummaryProvider
        self.clientProxy = clientProxy
        searchService = clientProxy.searchService
        
        super.init(initialViewState: SearchScreenViewState(bindings: .init(searchQuery: initialSearchQuery, searchMode: initialSearchMode)),
                   mediaProvider: mediaProvider)
        
        roomSummaryProvider.roomListPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] summaries in
                self?.updateRooms(with: summaries)
            }
            .store(in: &cancellables)
        
        searchService.resultsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] results in
                guard let self else { return }
                // A previous query's fetch can complete after the field was cleared; drop its late results.
                guard !state.bindings.searchQuery.isEmpty else {
                    state.messages = []
                    return
                }
                state.messages = results.map { result in
                    SearchScreenMessage(result,
                                        roomSummary: clientProxy.roomSummaryForIdentifier(result.roomID),
                                        isOutgoing: result.sender.id == clientProxy.userID)
                }
            }
            .store(in: &cancellables)
        
        searchService.paginationStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] paginationState in
                self?.state.isLoadingMessages = paginationState == .loading
            }
            .store(in: &cancellables)
        
        let debouncedSearchQueryStream = context.observe(\.viewState.bindings.searchQuery).debounce(for: .milliseconds(250)).removeDuplicates()
        searchQueryObservationTask = Task { [weak self] in
            for await searchQuery in debouncedSearchQueryStream {
                self?.updateFilter(for: searchQuery)
            }
        }
        
        // Flip the loading indicator on the moment the user starts typing, ahead of the debounced
        // query above, so the empty state doesn't flash while the first search is still pending.
        let searchQueryStream = context.observe(\.viewState.bindings.searchQuery).removeDuplicates()
        loadingObservationTask = Task { [weak self] in
            for await searchQuery in searchQueryStream {
                self?.state.isLoadingRooms = !searchQuery.isEmpty
                self?.state.isLoadingMessages = !searchQuery.isEmpty
            }
        }
        
        updateRooms(with: roomSummaryProvider.roomListPublisher.value)
    }
    
    isolated deinit {
        searchQueryObservationTask?.cancel()
        loadingObservationTask?.cancel()
        setQueryTask?.cancel()
    }
    
    // MARK: - Public
    
    override func process(viewAction: SearchScreenViewAction) {
        MXLog.info("View model: received view action: \(viewAction)")
        
        switch viewAction {
        case .appeared:
            // The provider is shared, so other consumers may have changed its filter while we were off-screen.
            // Re-apply ours on every appearance to keep the displayed results in sync with the query.
            updateFilter(for: state.bindings.searchQuery)
        case .selectRoom(let roomID):
            actionsSubject.send(.presentRoom(roomID: roomID, eventID: nil))
        case .selectMessage(let roomID, let eventID):
            actionsSubject.send(.presentRoom(roomID: roomID, eventID: eventID))
        case .reachedTop:
            if state.bindings.searchMode == .rooms {
                updateVisibleRange(edge: .top)
            }
        case .reachedBottom:
            switch state.bindings.searchMode {
            case .rooms:
                updateVisibleRange(edge: .bottom)
            case .messages:
                Task { await searchService.paginate() }
            }
        case .cancel:
            actionsSubject.send(.cancel)
        }
    }
    
    // MARK: - Private
    
    private func updateFilter(for searchQuery: String) {
        // Supersede any in-flight query so its results can't land after a newer one's.
        setQueryTask?.cancel()
        
        if searchQuery.isEmpty {
            roomSummaryProvider.setFilter(.excludeAll)
            state.messages = []
        } else {
            roomSummaryProvider.setFilter(.search(query: searchQuery))
            setQueryTask = Task { [weak self] in
                await self?.searchService.setQuery(searchQuery)
            }
        }
    }
    
    private func updateRooms(with summaries: [RoomSummary]) {
        // The list has caught up with the current filter, so we're no longer waiting on results.
        state.isLoadingRooms = false
        state.rooms = summaries.map { summary in
            let identifier = if summary.isDirect {
                summary.heroes.first?.id ?? summary.canonicalAlias
            } else {
                summary.canonicalAlias
            }
            
            return SearchScreenRoom(id: summary.id,
                                    title: summary.name,
                                    description: identifier ?? "",
                                    avatar: summary.avatar)
        }
    }
    
    /// The actual range values don't matter as long as they contain the lower
    /// or upper bounds. updateVisibleRange is a hybrid API that powers both
    /// sliding sync visible range update and list paginations.
    /// For lists other than the home screen one we don't care about visible ranges,
    /// we just need the respective bounds to be there to trigger a next page load or
    /// a reset to just one page.
    private func updateVisibleRange(edge: UIRectEdge) {
        switch edge {
        case .top:
            roomSummaryProvider.updateVisibleRange(0..<0)
        case .bottom:
            let roomCount = roomSummaryProvider.roomListPublisher.value.count
            roomSummaryProvider.updateVisibleRange(roomCount..<roomCount)
        default:
            break
        }
    }
}

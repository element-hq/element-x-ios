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
    private let userIndicatorController: UserIndicatorControllerProtocol
    private var searchQueryObservationTask: Task<Void, Never>?
    private var searchModeObservationTask: Task<Void, Never>?
    private var loadingObservationTask: Task<Void, Never>?
    private var setQueryTask: Task<Void, Never>?
    /// The query each tab last searched, so switching tabs only re-searches when the query changed.
    private var searchedQueries: [SearchScreenMode: String] = [:]
    
    private let actionsSubject: PassthroughSubject<SearchScreenViewModelAction, Never> = .init()
    var actionsPublisher: AnyPublisher<SearchScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(roomSummaryProvider: RoomSummaryProviderProtocol,
         clientProxy: ClientProxyProtocol,
         mediaProvider: MediaProviderProtocol,
         userIndicatorController: UserIndicatorControllerProtocol,
         initialSearchQuery: String = "",
         initialSearchMode: SearchScreenMode = .rooms) {
        self.roomSummaryProvider = roomSummaryProvider
        searchService = clientProxy.searchService
        self.userIndicatorController = userIndicatorController
        
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
        
        // Room search is fast so it reacts to every keystroke; message search debounces inside updateFilter.
        let searchQueryStream = context.observe(\.viewState.bindings.searchQuery).removeDuplicates()
        searchQueryObservationTask = Task { [weak self] in
            for await searchQuery in searchQueryStream {
                self?.updateFilter(for: searchQuery)
            }
        }
        
        // Re-run the search when switching tabs so the newly active tab reflects the current query.
        let searchModeStream = context.observe(\.viewState.bindings.searchMode).removeDuplicates()
        searchModeObservationTask = Task { [weak self] in
            for await _ in searchModeStream {
                guard let self else { return }
                updateFilter(for: state.bindings.searchQuery)
            }
        }
        
        // Flip the loading indicator on the moment the user starts typing, ahead of the debounced
        // message query above, so the empty state doesn't flash while the first search is still pending.
        let loadingQueryStream = context.observe(\.viewState.bindings.searchQuery).removeDuplicates()
        loadingObservationTask = Task { [weak self] in
            for await searchQuery in loadingQueryStream {
                self?.setActiveTabLoading(!searchQuery.isEmpty)
            }
        }
        
        updateRooms(with: roomSummaryProvider.roomListPublisher.value)
    }
    
    isolated deinit {
        searchQueryObservationTask?.cancel()
        searchModeObservationTask?.cancel()
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
            updateFilter(for: state.bindings.searchQuery, forced: true)
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
    
    private func updateFilter(for searchQuery: String, forced: Bool = false) {
        guard !searchQuery.isEmpty else {
            // Supersede any in-flight query so its results can't land after a newer one's.
            setQueryTask?.cancel()
            searchedQueries.removeAll()
            roomSummaryProvider.setFilter(.excludeAll)
            state.messages = []
            return
        }
        
        // Only search the active tab. Room search is fast while message search is slow, so we
        // avoid one blocking the other; the other tab is (re)searched when it becomes active.
        let mode = state.bindings.searchMode
        // Skip a tab that already ran this query (e.g. switching back and forth) unless forced.
        guard forced || searchedQueries[mode] != searchQuery else { return }
        
        setQueryTask?.cancel()
        setActiveTabLoading(true)
        switch mode {
        case .rooms:
            searchedQueries[mode] = searchQuery
            roomSummaryProvider.setFilter(.search(query: searchQuery))
        case .messages:
            setQueryTask = Task { [weak self] in
                // Debounce message queries; superseded keystrokes cancel this before it commits.
                try? await Task.sleep(for: .milliseconds(250))
                guard let self, !Task.isCancelled else { return }
                searchedQueries[mode] = searchQuery
                if case .failure = await searchService.setQuery(searchQuery), !Task.isCancelled {
                    userIndicatorController.submitIndicator(.init(title: L10n.errorUnknown))
                }
            }
        }
    }
    
    private func setActiveTabLoading(_ isLoading: Bool) {
        switch state.bindings.searchMode {
        case .rooms:
            state.isLoadingRooms = isLoading
        case .messages:
            state.isLoadingMessages = isLoading
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

//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias SearchScreenViewModelType = StateStoreViewModelV2<SearchScreenViewState, SearchScreenViewAction>

class SearchScreenViewModel: SearchScreenViewModelType, SearchScreenViewModelProtocol {
    private let roomSummaryProvider: RoomSummaryProviderProtocol
    private var searchQueryObservationTask: Task<Void, Never>?
    
    private let actionsSubject: PassthroughSubject<SearchScreenViewModelAction, Never> = .init()
    var actionsPublisher: AnyPublisher<SearchScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(roomSummaryProvider: RoomSummaryProviderProtocol,
         mediaProvider: MediaProviderProtocol,
         initialSearchQuery: String = "") {
        self.roomSummaryProvider = roomSummaryProvider
        
        super.init(initialViewState: SearchScreenViewState(bindings: .init(searchQuery: initialSearchQuery)),
                   mediaProvider: mediaProvider)
        
        roomSummaryProvider.roomListPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] summaries in
                self?.updateRooms(with: summaries)
            }
            .store(in: &cancellables)
        
        searchQueryObservationTask = Task { [weak self] in
            guard let stream = self?.context.observe(\.viewState.bindings.searchQuery) else { return }
            var lastQuery: String?
            for await searchQuery in stream {
                guard searchQuery != lastQuery else { continue }
                lastQuery = searchQuery
                if searchQuery.isEmpty {
                    self?.roomSummaryProvider.setFilter(.excludeAll)
                } else {
                    self?.roomSummaryProvider.setFilter(.search(query: searchQuery))
                }
            }
        }
        
        updateRooms(with: roomSummaryProvider.roomListPublisher.value)
    }
    
    isolated deinit {
        searchQueryObservationTask?.cancel()
    }
    
    func stop() {
        searchQueryObservationTask?.cancel()
        // This is a shared provider so we should reset the filtering when we are done with the view.
        roomSummaryProvider.setFilter(.all(filters: []))
    }
    
    // MARK: - Public
    
    override func process(viewAction: SearchScreenViewAction) {
        MXLog.info("View model: received view action: \(viewAction)")
        
        switch viewAction {
        case .selectRoom(let roomID):
            actionsSubject.send(.presentRoom(roomID: roomID))
        case .reachedTop:
            updateVisibleRange(edge: .top)
        case .reachedBottom:
            updateVisibleRange(edge: .bottom)
        }
    }
    
    // MARK: - Private
    
    private func updateRooms(with summaries: [RoomSummary]) {
        state.rooms = summaries.map { summary in
            // Show the matrix identifier as the subtitle: the other member's user ID for DMs,
            // otherwise the room's canonical alias.
            let identifier = if summary.isDirect {
                summary.heroes.first?.userID ?? summary.canonicalAlias
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

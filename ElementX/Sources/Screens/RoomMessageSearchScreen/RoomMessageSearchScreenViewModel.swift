//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias RoomMessageSearchScreenViewModelType = StateStoreViewModel<RoomMessageSearchScreenViewState, RoomMessageSearchScreenViewAction>

class RoomMessageSearchScreenViewModel: RoomMessageSearchScreenViewModelType, RoomMessageSearchScreenViewModelProtocol {
    private let roomProxy: JoinedRoomProxyProtocol
    private var searchProxy: RoomMessageSearchProxyProtocol?

    private let actionsSubject: PassthroughSubject<RoomMessageSearchScreenViewModelAction, Never> = .init()
    var actionsPublisher: AnyPublisher<RoomMessageSearchScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(roomProxy: JoinedRoomProxyProtocol, mediaProvider: MediaProviderProtocol?) {
        self.roomProxy = roomProxy

        super.init(initialViewState: RoomMessageSearchScreenViewState(bindings: .init()), mediaProvider: mediaProvider)

        context.$viewState.map(\.bindings.searchQuery)
            .debounceTextQueriesAndRemoveDuplicates()
            .sink { [weak self] query in
                self?.search(query: query)
            }
            .store(in: &cancellables)
    }

    // MARK: - Public

    override func process(viewAction: RoomMessageSearchScreenViewAction) {
        switch viewAction {
        case .dismiss:
            actionsSubject.send(.dismiss)
        case .selectResult(let eventID):
            actionsSubject.send(.displayEvent(eventID: eventID))
        case .reachedBottom:
            loadNextResults()
        }
    }

    // MARK: - Private

    private func search(query: String) {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)

        state.results = []
        state.hasSearched = false
        // Reset so an old in-flight load doesn't block this search
        state.isLoading = false

        guard !trimmedQuery.isEmpty else {
            searchProxy = nil
            return
        }

        searchProxy = roomProxy.messageSearchProxy(query: trimmedQuery)
        loadNextResults()
    }

    private func loadNextResults() {
        guard let searchProxy, !state.isLoading else { return }

        state.isLoading = true
        Task {
            let result = await searchProxy.loadNextResults()

            // Ignore results from a previous search
            guard self.searchProxy === searchProxy else { return }

            switch result {
            case .success(let results):
                if let results {
                    state.results += results
                } else {
                    // No more results, so stop paginating
                    self.searchProxy = nil
                }
            case .failure(let error):
                MXLog.error("Failed loading message search results: \(error)")
                self.searchProxy = nil
            }

            state.hasSearched = true
            state.isLoading = false
        }
    }
}

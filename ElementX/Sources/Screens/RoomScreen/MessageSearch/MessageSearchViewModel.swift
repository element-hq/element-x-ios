//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import MatrixRustSDK
import SwiftUI

typealias MessageSearchViewModelType = StateStoreViewModel<MessageSearchViewState, MessageSearchViewAction>

class MessageSearchViewModel: MessageSearchViewModelType {
    private let roomProxy: JoinedRoomProxyProtocol
    private let actionsSubject: PassthroughSubject<MessageSearchViewModelAction, Never> = .init()
    
    var actionsPublisher: AnyPublisher<MessageSearchViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(roomProxy: JoinedRoomProxyProtocol) {
        self.roomProxy = roomProxy
        super.init(initialViewState: MessageSearchViewState())
    }
    
    // MARK: - Public
    
    func start() {
        // Setup search debouncing
        context.$viewState
            .map(\.bindings.searchQuery)
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] query in
                guard let self else { return }
                if !query.isEmpty {
                    self.performSearch(query: query)
                }
            }
            .store(in: &cancellables)
    }
    
    func stop() {
        // No cleanup needed - cancellables are handled by parent class
    }
    
    override func process(viewAction: MessageSearchViewAction) {
        switch viewAction {
        case .searchQueryChanged(let query):
            state.bindings.searchQuery = query
            if query.isEmpty {
                state.searchResults = []
                state.hasSearched = false
            }
        case .clearSearch:
            state.bindings.searchQuery = ""
            state.searchResults = []
            state.hasSearched = false
        case .selectMessage(let eventID):
            actionsSubject.send(.selectMessage(eventID: eventID))
        case .dismiss:
            actionsSubject.send(.dismiss)
        }
    }
    
    // MARK: - Private
    
    private func performSearch(query: String) {
        state.isLoading = true
        state.hasSearched = true
        
        Task {
            let results = await searchMessagesInRoom(query: query)
            
            await MainActor.run {
                state.searchResults = results
                state.isLoading = false
            }
        }
    }
    
    private func searchMessagesInRoom(query: String) async -> [MessageSearchResult] {
        // Get timeline items from the room
        let timelineItems = roomProxy.timeline.timelineItemProvider.itemProxies
        
        // Filter for event items (actual messages)
        let eventItems = timelineItems.compactMap { item -> EventTimelineItemProxy? in
            switch item {
            case .event(let eventItem):
                return eventItem
            default:
                return nil
            }
        }
        
        // Filter for text messages and search within content
        var searchResults: [MessageSearchResult] = []
        
        for eventItem in eventItems {
            // Check if this is a text message
            guard case .msgLike(let messageLikeContent) = eventItem.content,
                  case .message(let messageContent) = messageLikeContent.kind else {
                continue
            }
            
            // Get message content and sender
            let content = messageContent.body
            let sender = eventItem.sender
            
            // Search in content or sender name
            if content.localizedCaseInsensitiveContains(query) ||
                (sender.displayName?.localizedCaseInsensitiveContains(query) ?? false) ||
                sender.id.localizedCaseInsensitiveContains(query) {
                let result = MessageSearchResult(id: eventItem.id.uniqueID.value,
                                                 eventID: eventItem.id.eventID ?? "",
                                                 sender: sender.displayName ?? sender.id,
                                                 content: content,
                                                 timestamp: eventItem.timestamp,
                                                 roomID: roomProxy.id)
                
                searchResults.append(result)
            }
        }
        
        // Sort by timestamp (newest first)
        searchResults.sort { $0.timestamp > $1.timestamp }
        
        return searchResults
    }
}

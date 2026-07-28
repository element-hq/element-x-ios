//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

enum RoomMessageSearchScreenViewModelAction: Equatable {
    case presentEvent(eventID: String)
}

struct RoomMessageSearchScreenViewState: BindableState {
    var bindings = RoomMessageSearchScreenViewStateBindings()
    
    var results: [RoomMessageSearchResult] = []
    /// A keystroke has been made but the debounced query hasn't reached the SDK yet.
    var isSearching = false
    /// A page of results is currently being loaded.
    var isPaginating = false
    /// Every source has been exhausted for the current query.
    var endReached = false
    var hasError = false
    
    private var hasQuery: Bool {
        !bindings.searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var displayInitialState: Bool {
        !hasQuery && !hasError
    }
    
    /// Only preempt the list with a full-screen error when there is nothing to show; a failed
    /// background page must not hide results that already loaded.
    var displayErrorState: Bool {
        hasError && results.isEmpty
    }
    
    /// Only claim "no results" once the walk has genuinely exhausted the index.
    var displayEmptyState: Bool {
        hasQuery && results.isEmpty && !hasError && !isSearching && !isPaginating && endReached
    }
    
    /// Room scoping filters a globally ranked set, so any empty moment before `endReached`
    /// belongs to the walk — never render it as "no results".
    var displaySearchingState: Bool {
        hasQuery && results.isEmpty && !hasError && !endReached
    }
    
    /// The footer spinner renders only while a page is genuinely in flight.
    var displayLoadMoreIndicator: Bool {
        !results.isEmpty && !endReached && !hasError && isPaginating
    }
}

struct RoomMessageSearchScreenViewStateBindings {
    var searchQuery = ""
}

enum RoomMessageSearchScreenViewAction {
    case selectResult(eventID: String)
    /// Reported as a state rather than a "load one more" command: pages must be requested one
    /// at a time and awaited, and only the view model can see when one has finished.
    case listEndVisible(Bool)
}

struct RoomMessageSearchResult: Identifiable, Equatable {
    let id: String
    let sender: TimelineItemSender
    let senderName: String
    /// Retained so media results can render the media-preview row (the text `preview` is nil
    /// for image/video/audio/file content) — mirrors `SearchScreenMessage`.
    let content: TimelineEventContent
    let preview: AttributedString?
    let timestamp: Date
    
    init(_ result: SearchServiceResult, isOutgoing: Bool) {
        id = result.eventID
        sender = result.sender
        senderName = isOutgoing ? L10n.commonYou : result.sender.disambiguatedDisplayName ?? result.sender.id
        content = result.content
        preview = result.content.searchPreviewBody
        timestamp = result.timestamp
    }
    
    var mediaPreview: SearchScreenMediaPreview? {
        content.searchMediaPreview
    }
}

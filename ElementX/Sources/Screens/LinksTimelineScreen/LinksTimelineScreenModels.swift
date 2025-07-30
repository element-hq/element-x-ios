//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

// MARK: - Coordinator

// MARK: View model

enum LinksTimelineScreenViewModelAction: Equatable {
    case openURL(URL)
    case shareURL(URL)
    case navigateToMessage(eventID: String)
    case close
}

// MARK: View

struct LinkItem: Identifiable, Hashable {
    let id: String
    let url: URL
    let title: String?
    let sender: TimelineItemSender
    let timestamp: Date
    let eventID: String
    
    init(url: URL, sender: TimelineItemSender, timestamp: Date, eventID: String, title: String? = nil) {
        self.id = eventID
        self.url = url
        self.title = title
        self.sender = sender
        self.timestamp = timestamp
        self.eventID = eventID
    }
}

struct LinksTimelineScreenViewState: BindableState {
    var roomTitle: String
    var links: [LinkItem] = []
    var isLoading = false
    var errorMessage: String?
    
    var shouldShowEmptyState: Bool {
        !isLoading && links.isEmpty && errorMessage == nil
    }
    
    var shouldShowErrorState: Bool {
        !isLoading && errorMessage != nil
    }
    
    var bindings = LinksTimelineScreenViewStateBindings()
}

struct LinksTimelineScreenViewStateBindings {
    var selectedSenderFilter: String? = nil
    var availableSenders: [String] = []
}

enum LinksTimelineScreenViewAction {
    case openURL(URL)
    case shareURL(URL)
    case navigateToMessage(eventID: String)
    case filterBySender(String?)
    case retry
    case close
} 
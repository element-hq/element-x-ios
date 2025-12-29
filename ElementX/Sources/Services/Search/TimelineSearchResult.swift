//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// Represents a search result from timeline full-text search
struct TimelineSearchResult: Identifiable, Equatable {
    let id: String
    let eventID: String
    let timestamp: Date
    let senderID: String
    let senderDisplayName: String?
    let messageSnippet: String
    let highlightRanges: [NSRange]
    let roomID: String
    
    init(eventID: String,
         timestamp: Date,
         senderID: String,
         senderDisplayName: String?,
         messageSnippet: String,
         highlightRanges: [NSRange],
         roomID: String) {
        self.id = eventID
        self.eventID = eventID
        self.timestamp = timestamp
        self.senderID = senderID
        self.senderDisplayName = senderDisplayName
        self.messageSnippet = messageSnippet
        self.highlightRanges = highlightRanges
        self.roomID = roomID
    }
}

/// Progress information for ongoing timeline search
struct TimelineSearchProgress {
    let isSearching: Bool
    let resultsCount: Int
    let pagesScanned: Int
    let hasReachedTimelineStart: Bool
    
    static let initial = TimelineSearchProgress(
        isSearching: false,
        resultsCount: 0,
        pagesScanned: 0,
        hasReachedTimelineStart: false
    )
}

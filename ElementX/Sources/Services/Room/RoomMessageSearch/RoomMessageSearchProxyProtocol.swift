//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

// sourcery: AutoMockable
protocol RoomMessageSearchProxyProtocol: AnyObject {
    /// Loads the next batch of search results.
    /// Returns `nil` when there are no more results for the query,
    /// in which case the proxy should not be queried again.
    func loadNextResults() async -> Result<[RoomMessageSearchResult]?, RoomProxyError>
}

struct RoomMessageSearchResult: Identifiable, Equatable {
    /// The matching event's ID, used to focus the timeline on it.
    let id: String
    let sender: TimelineItemSender
    let timestamp: Date
    let message: AttributedString?
}

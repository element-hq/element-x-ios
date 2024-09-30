//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

struct TimelineItemReply {
    let details: TimelineItemReplyDetails
    let isThreaded: Bool
}

enum TimelineItemReplyDetails: Hashable {
    case notLoaded(eventID: String)
    case loading(eventID: String)
    case loaded(sender: TimelineItemSender, eventID: String, eventContent: TimelineEventContent)
    case error(eventID: String, message: String)
    
    var eventID: String {
        switch self {
        case .notLoaded(let eventID), .loading(let eventID), .loaded(_, let eventID, _), .error(let eventID, _):
            return eventID
        }
    }
}

enum TimelineEventContent: Hashable {
    case message(EventBasedMessageTimelineItemContentType)
    case poll(question: String)
    case redacted
}

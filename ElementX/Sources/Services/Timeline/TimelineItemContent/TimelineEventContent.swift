//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

nonisolated enum TimelineEventContent: Hashable, CustomStringConvertible {
    case message(EventBasedMessageTimelineItemContentType)
    case poll(question: String)
    case liveLocation
    case redacted
    
    var description: String {
        switch self {
        case .message(let eventBasedMessageTimelineItemContentType):
            eventBasedMessageTimelineItemContentType.description
        case .poll:
            "poll"
        case .liveLocation:
            "liveLocation"
        case .redacted:
            "redacted"
        }
    }
}

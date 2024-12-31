//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

struct LocationRoomTimelineItem: EventBasedMessageTimelineItemProtocol, Equatable {
    let id: TimelineItemIdentifier

    let timestamp: Date
    let isOutgoing: Bool
    let isEditable: Bool
    let canBeRepliedTo: Bool
    let isThreaded: Bool
    
    let sender: TimelineItemSender

    let content: LocationRoomTimelineItemContent

    var body: String {
        content.body
    }

    var replyDetails: TimelineItemReplyDetails?

    var properties = RoomTimelineItemProperties()

    var contentType: EventBasedMessageTimelineItemContentType {
        .location(content)
    }
}

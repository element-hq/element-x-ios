//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

struct LocationRoomTimelineItem: EventBasedMessageTimelineItemProtocol, Equatable {
    let id: TimelineItemIdentifier

    let timestamp: String
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

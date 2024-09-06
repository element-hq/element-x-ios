//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import UIKit

struct TextRoomTimelineItem: TextBasedRoomTimelineItem, Equatable {
    let id: TimelineItemIdentifier
    
    let timestamp: String
    let isOutgoing: Bool
    let isEditable: Bool
    let canBeRepliedTo: Bool
    
    let isThreaded: Bool
    
    let sender: TimelineItemSender
    
    let content: TextRoomTimelineItemContent
    
    var replyDetails: TimelineItemReplyDetails?
    
    var properties = RoomTimelineItemProperties()
    
    var body: String {
        content.body
    }
    
    var contentType: EventBasedMessageTimelineItemContentType {
        .text(content)
    }
}

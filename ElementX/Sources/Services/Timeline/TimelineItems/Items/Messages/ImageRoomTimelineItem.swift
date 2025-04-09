//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import UIKit
import UniformTypeIdentifiers

struct ImageRoomTimelineItem: EventBasedMessageTimelineItemProtocol, Equatable {
    let id: TimelineItemIdentifier
    let timestamp: Date
    let isOutgoing: Bool
    let isEditable: Bool
    let canBeRepliedTo: Bool
    var shouldBoost = false
    
    let sender: TimelineItemSender
    
    let content: ImageRoomTimelineItemContent
    
    var properties = RoomTimelineItemProperties()
    
    var body: String {
        content.caption ?? content.filename
    }
    
    var contentType: EventBasedMessageTimelineItemContentType {
        .image(content)
    }
}

//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import UIKit

struct GalleryRoomTimelineItem: EventBasedMessageTimelineItemProtocol, Equatable {
    let id: TimelineItemIdentifier
    let timestamp: Date
    let isOutgoing: Bool
    let isEditable: Bool
    let canBeRepliedTo: Bool
    var shouldBoost = false
    
    let sender: TimelineItemSender
    
    let content: GalleryRoomTimelineItemContent
    
    var properties = RoomTimelineItemProperties()
    
    var body: String {
        content.caption ?? content.body
    }
    
    var contentType: EventBasedMessageTimelineItemContentType {
        .gallery(content)
    }
}

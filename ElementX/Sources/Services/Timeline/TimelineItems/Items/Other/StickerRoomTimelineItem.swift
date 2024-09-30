//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import UIKit

struct StickerRoomTimelineItem: EventBasedTimelineItemProtocol, Equatable {
    let id: TimelineItemIdentifier
    let body: String
    let timestamp: String
    let isOutgoing: Bool
    let isEditable: Bool
    let canBeRepliedTo: Bool
    
    let sender: TimelineItemSender
    
    let imageURL: URL
    
    var width: CGFloat?
    var height: CGFloat?
    var aspectRatio: CGFloat?
    var blurhash: String?
    
    var properties = RoomTimelineItemProperties()
}

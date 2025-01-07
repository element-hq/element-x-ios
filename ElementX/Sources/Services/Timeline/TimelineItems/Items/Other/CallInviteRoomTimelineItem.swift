//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

struct CallInviteRoomTimelineItem: RoomTimelineItemProtocol, Equatable {
    let id: TimelineItemIdentifier
    let timestamp: Date
    let isEditable: Bool
    let canBeRepliedTo: Bool
    
    let sender: TimelineItemSender
    
    var properties = RoomTimelineItemProperties()
}

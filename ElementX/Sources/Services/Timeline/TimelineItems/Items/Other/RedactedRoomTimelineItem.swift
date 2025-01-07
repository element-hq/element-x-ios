//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import UIKit

struct RedactedRoomTimelineItem: EventBasedTimelineItemProtocol, Equatable {
    let id: TimelineItemIdentifier
    let body: String
    let timestamp: Date
    let isOutgoing: Bool
    let isEditable: Bool
    let canBeRepliedTo: Bool
    
    let sender: TimelineItemSender
    
    var properties = RoomTimelineItemProperties()
}

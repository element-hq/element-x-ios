//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

struct CollapsibleTimelineItem: RoomTimelineItemProtocol, Equatable {
    let id: TimelineItemIdentifier
    let items: [RoomTimelineItemProtocol]
    let itemIDs: [TimelineItemIdentifier]
    
    init(items: [RoomTimelineItemProtocol]) {
        self.items = items
        itemIDs = items.map(\.id)
        
        guard let firstItemID = itemIDs.first else {
            fatalError()
        }
        
        id = firstItemID
    }
    
    // MARK: - Equatable
    
    static func == (lhs: CollapsibleTimelineItem, rhs: CollapsibleTimelineItem) -> Bool {
        // Technically not a correct implementation of equality as the items themselves could be updated.
        lhs.id == rhs.id && lhs.itemIDs == rhs.itemIDs
    }
}

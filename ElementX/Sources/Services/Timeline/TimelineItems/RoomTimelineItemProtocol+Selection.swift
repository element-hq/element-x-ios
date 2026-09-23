//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

extension [RoomTimelineItemProtocol] {
    /// The items that can be forwarded, in timeline order.
    var forwardableItems: [EventBasedTimelineItemProtocol] {
        compactMap { item in
            guard let item = item as? EventBasedTimelineItemProtocol, item.isForwardable else { return nil }
            return item
        }
    }
    
    /// The selected items in timeline order, whatever the order they were selected in.
    func selectedItems(_ selectedEventIDs: Set<String>) -> [EventBasedTimelineItemProtocol] {
        forwardableItems.filter { item in
            guard let eventID = item.id.eventID else { return false }
            return selectedEventIDs.contains(eventID)
        }
    }
}

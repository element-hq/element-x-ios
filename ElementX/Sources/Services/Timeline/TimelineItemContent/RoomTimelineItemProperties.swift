//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

/// Properties of a matrix event that are common between all timeline items.
struct RoomTimelineItemProperties: Hashable {
    /// Whether the item has been edited.
    var isEdited = false
    /// The aggregated reactions that have been sent for this item.
    var reactions: [AggregatedReaction] = []
    /// The delivery status for this item. If a sent message is echoed the value is nil.
    var deliveryStatus: TimelineItemDeliveryStatus?
    /// The read receipts of the item, ordered from newest to oldest.
    var orderedReadReceipts: [ReadReceipt] = []
    /// Authenticity warnings for item's sent in encrypted rooms.
    var encryptionAuthenticity: EncryptionAuthenticity?
}

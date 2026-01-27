//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// Properties of a matrix event that are common between all timeline items.
struct RoomTimelineItemProperties: Hashable {
    /// Information on the item this one replying to
    var replyDetails: TimelineItemReplyDetails?
    /// Whether it's part of a thread or not
    var isThreaded = false
    /// Information about the thread this message is the root of, if any
    var threadSummary: TimelineItemThreadSummary?
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
    /// Information about the forwarder of the keys used to decrypt this message.
    var encryptionForwarder: TimelineItemKeyForwarder?
}

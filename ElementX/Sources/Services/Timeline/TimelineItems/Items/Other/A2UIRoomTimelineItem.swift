//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// An `m.room.message` carrying A2UI surfaces (`msgtype` ``A2UIEvent/messageType``).
nonisolated struct A2UIRoomTimelineItem: EventBasedTimelineItemProtocol, Equatable {
    let id: TimelineItemIdentifier
    /// The plain-text fallback, shown when A2UI rendering is disabled.
    let body: String
    let timestamp: Date
    let isOutgoing: Bool
    let isEditable: Bool
    let canBeRepliedTo: Bool
    let sender: TimelineItemSender
    var content: A2UIRoomTimelineItemContent
    var properties = RoomTimelineItemProperties()
    
    /// Attaches the updates that belong to this message. Only updates from the message's
    /// sender are applied, in the (timeline) order they were received.
    func applyingUpdates(_ updates: [A2UIUpdate]) -> A2UIRoomTimelineItem {
        var item = self
        item.content.updates = updates.filter { $0.senderID == sender.id }
        return item
    }
}

nonisolated struct A2UIRoomTimelineItemContent: Hashable, Sendable {
    /// The messages carried by the event itself.
    let messages: [A2UIServerMessage]
    /// The updates related to the event, in the order received.
    var updates: [A2UIUpdate] = []
    
    /// Everything to apply to build the surfaces, in order.
    var allMessages: [A2UIServerMessage] {
        messages + updates.flatMap(\.messages)
    }
}

nonisolated extension A2UIUpdate {
    /// The update events among the timeline's items, grouped by the event they reference.
    static func updates(in itemProxies: [TimelineItemProxy]) -> [String: [A2UIUpdate]] {
        var updates: [String: [A2UIUpdate]] = [:]
        for case .event(let proxy) in itemProxies where proxy.item.eventTypeRaw == A2UIEvent.updateEventType {
            guard let eventJSON = proxy.latestJSON,
                  let content = A2UIEvent.content(ofEventJSON: eventJSON),
                  let update = A2UIUpdate(content: content, senderID: proxy.item.sender) else {
                continue
            }
            updates[update.referencedEventID, default: []].append(update)
        }
        return updates
    }
}

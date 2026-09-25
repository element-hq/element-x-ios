//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Testing

@MainActor
struct TimelineItemsSelectionTests {
    @Test
    func selectedItemsFollowTheTimelineNotTheSelection() {
        let items: [RoomTimelineItemProtocol] = (1...5).map { makeTextItem(eventID: "$\($0)") }
        
        let ordered = items.selectedItems(["$5", "$1", "$3"])
        
        #expect(ordered.map(\.id) == [items[0].id, items[2].id, items[4].id])
    }
    
    @Test
    func selectedItemsSkipUnforwardableAndUnknownEvents() {
        let text = makeTextItem(eventID: "$1")
        let redacted = RedactedRoomTimelineItem(id: .event(uniqueID: .init("2"), eventOrTransactionID: .eventID("$2")),
                                                body: "Message removed",
                                                timestamp: .mock,
                                                isOutgoing: false,
                                                isEditable: false,
                                                canBeRepliedTo: false,
                                                sender: .init(id: "@alice:matrix.org"))
        let separator = SeparatorRoomTimelineItem(id: .virtual(uniqueID: .init("separator")), timestamp: .mock)
        
        let items: [RoomTimelineItemProtocol] = [separator, redacted, text]
        
        let ordered = items.selectedItems(["$1", "$2", "$missing"])
        
        #expect(ordered.map(\.id) == [text.id])
    }
    
    // MARK: - Helpers
    
    private func makeTextItem(eventID: String) -> TextRoomTimelineItem {
        .init(id: .event(uniqueID: .init(eventID), eventOrTransactionID: .eventID(eventID)),
              timestamp: .mock,
              isOutgoing: false,
              isEditable: false,
              canBeRepliedTo: true,
              sender: .init(id: "@alice:matrix.org"),
              content: .init(body: eventID))
    }
}

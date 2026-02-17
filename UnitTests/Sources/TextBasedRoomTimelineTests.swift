//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Foundation
import Testing

@Suite
struct TextBasedRoomTimelineTests {
    @Test
    func textRoomTimelineItemWhitespaceEnd() {
        let timestamp = Calendar.current.startOfDay(for: .now).addingTimeInterval(60 * 60) // 1:00 am
        let timelineItem = TextRoomTimelineItem(id: .randomEvent,
                                                timestamp: timestamp,
                                                isOutgoing: true,
                                                isEditable: true,
                                                canBeRepliedTo: true,
                                                sender: .init(id: UUID().uuidString),
                                                content: .init(body: "Test"))
        #expect(timelineItem.additionalWhitespaces() == timestamp.formattedTime().count + 1)
    }

    @Test
    func textRoomTimelineItemWhitespaceEndLonger() {
        let timestamp = Calendar.current.startOfDay(for: .now).addingTimeInterval(-60) // 11:59 pm
        let timelineItem = TextRoomTimelineItem(id: .randomEvent,
                                                timestamp: timestamp,
                                                isOutgoing: true,
                                                isEditable: true,
                                                canBeRepliedTo: true,
                                                sender: .init(id: UUID().uuidString),
                                                content: .init(body: "Test"))
        #expect(timelineItem.additionalWhitespaces() == timestamp.formattedTime().count + 1)
    }

    @Test
    func textRoomTimelineItemWhitespaceEndWithEdit() {
        let timestamp = Date.mock
        var timelineItem = TextRoomTimelineItem(id: .randomEvent,
                                                timestamp: timestamp,
                                                isOutgoing: true,
                                                isEditable: true,
                                                canBeRepliedTo: true,
                                                sender: .init(id: UUID().uuidString),
                                                content: .init(body: "Test"))
        timelineItem.properties.isEdited = true
        let editedCount = L10n.commonEditedSuffix.count
        #expect(timelineItem.additionalWhitespaces() == timestamp.formattedTime().count + editedCount + 2)
    }

    @Test
    func textRoomTimelineItemWhitespaceEndWithEditAndAlert() {
        let timestamp = Date.mock
        var timelineItem = TextRoomTimelineItem(id: .randomEvent,
                                                timestamp: timestamp,
                                                isOutgoing: true,
                                                isEditable: true,
                                                canBeRepliedTo: true,
                                                sender: .init(id: UUID().uuidString),
                                                content: .init(body: "Test"))
        timelineItem.properties.isEdited = true
        timelineItem.properties.deliveryStatus = .sendingFailed(.unknown)
        let editedCount = L10n.commonEditedSuffix.count
        #expect(timelineItem.additionalWhitespaces() == timestamp.formattedTime().count + editedCount + 5)
    }
}

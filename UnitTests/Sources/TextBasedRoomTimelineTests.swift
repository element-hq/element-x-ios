//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import XCTest

final class TextBasedRoomTimelineTests: XCTestCase {
    func testTextRoomTimelineItemWhitespaceEnd() {
        let timestamp = Calendar.current.startOfDay(for: .now).addingTimeInterval(60 * 60) // 1:00 am
        let timelineItem = TextRoomTimelineItem(id: .randomEvent,
                                                timestamp: timestamp,
                                                isOutgoing: true,
                                                isEditable: true,
                                                canBeRepliedTo: true,
                                                isThreaded: false,
                                                sender: .init(id: UUID().uuidString),
                                                content: .init(body: "Test"))
        XCTAssertEqual(timelineItem.additionalWhitespaces(), timestamp.formattedTime().count + 1)
    }

    func testTextRoomTimelineItemWhitespaceEndLonger() {
        let timestamp = Calendar.current.startOfDay(for: .now).addingTimeInterval(-60) // 11:59 pm
        let timelineItem = TextRoomTimelineItem(id: .randomEvent,
                                                timestamp: timestamp,
                                                isOutgoing: true,
                                                isEditable: true,
                                                canBeRepliedTo: true,
                                                isThreaded: false,
                                                sender: .init(id: UUID().uuidString),
                                                content: .init(body: "Test"))
        XCTAssertEqual(timelineItem.additionalWhitespaces(), timestamp.formattedTime().count + 1)
    }

    func testTextRoomTimelineItemWhitespaceEndWithEdit() {
        let timestamp = Date.mock
        var timelineItem = TextRoomTimelineItem(id: .randomEvent,
                                                timestamp: timestamp,
                                                isOutgoing: true,
                                                isEditable: true,
                                                canBeRepliedTo: true,
                                                isThreaded: false,
                                                sender: .init(id: UUID().uuidString),
                                                content: .init(body: "Test"))
        timelineItem.properties.isEdited = true
        let editedCount = L10n.commonEditedSuffix.count
        XCTAssertEqual(timelineItem.additionalWhitespaces(), timestamp.formattedTime().count + editedCount + 2)
    }

    func testTextRoomTimelineItemWhitespaceEndWithEditAndAlert() {
        let timestamp = Date.mock
        var timelineItem = TextRoomTimelineItem(id: .randomEvent,
                                                timestamp: timestamp,
                                                isOutgoing: true,
                                                isEditable: true,
                                                canBeRepliedTo: true,
                                                isThreaded: false,
                                                sender: .init(id: UUID().uuidString),
                                                content: .init(body: "Test"))
        timelineItem.properties.isEdited = true
        timelineItem.properties.deliveryStatus = .sendingFailed(.unknown)
        let editedCount = L10n.commonEditedSuffix.count
        XCTAssertEqual(timelineItem.additionalWhitespaces(), timestamp.formattedTime().count + editedCount + 5)
    }
}

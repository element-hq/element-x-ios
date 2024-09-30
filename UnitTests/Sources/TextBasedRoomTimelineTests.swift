//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

@testable import ElementX
import XCTest

final class TextBasedRoomTimelineTests: XCTestCase {
    func testTextRoomTimelineItemWhitespaceEnd() {
        let timestamp = "Now"
        let timelineItem = TextRoomTimelineItem(id: .random,
                                                timestamp: timestamp,
                                                isOutgoing: true,
                                                isEditable: true,
                                                canBeRepliedTo: true,
                                                isThreaded: false,
                                                sender: .init(id: UUID().uuidString),
                                                content: .init(body: "Test"))
        XCTAssertEqual(timelineItem.additionalWhitespaces(), timestamp.count + 1)
    }

    func testTextRoomTimelineItemWhitespaceEndLonger() {
        let timestamp = "10:00 AM"
        let timelineItem = TextRoomTimelineItem(id: .random,
                                                timestamp: timestamp,
                                                isOutgoing: true,
                                                isEditable: true,
                                                canBeRepliedTo: true,
                                                isThreaded: false,
                                                sender: .init(id: UUID().uuidString),
                                                content: .init(body: "Test"))
        XCTAssertEqual(timelineItem.additionalWhitespaces(), timestamp.count + 1)
    }

    func testTextRoomTimelineItemWhitespaceEndWithEdit() {
        let timestamp = "Now"
        var timelineItem = TextRoomTimelineItem(id: .random,
                                                timestamp: timestamp,
                                                isOutgoing: true,
                                                isEditable: true,
                                                canBeRepliedTo: true,
                                                isThreaded: false,
                                                sender: .init(id: UUID().uuidString),
                                                content: .init(body: "Test"))
        timelineItem.properties.isEdited = true
        let editedCount = L10n.commonEditedSuffix.count
        XCTAssertEqual(timelineItem.additionalWhitespaces(), timestamp.count + editedCount + 2)
    }

    func testTextRoomTimelineItemWhitespaceEndWithEditAndAlert() {
        let timestamp = "Now"
        var timelineItem = TextRoomTimelineItem(id: .random,
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
        XCTAssertEqual(timelineItem.additionalWhitespaces(), timestamp.count + editedCount + 5)
    }
}

//
// Copyright 2023 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

@testable import ElementX
import XCTest

final class TextBasedRoomTimelineTests: XCTestCase {
    func testTextRoomTimelineItemWhitespaceEnd() {
        let timestamp = "Now"
        let timelineItem = TextRoomTimelineItem(id: .init(timelineID: UUID().uuidString), timestamp: timestamp, isOutgoing: true, isEditable: true, sender: .init(id: UUID().uuidString), content: .init(body: "Test"))
        let view = TextBasedRoomTimelineViewMock<TextRoomTimelineItem>()
        view.underlyingTimelineItem = timelineItem
        view.timelineStyle = .bubbles

        XCTAssertEqual(view.additionalWhitespaces, timestamp.count + 1)
    }

    func testTextRoomTimelineItemWhitespaceEndLonger() {
        let timestamp = "10:00 AM"
        let timelineItem = TextRoomTimelineItem(id: .init(timelineID: UUID().uuidString), timestamp: timestamp, isOutgoing: true, isEditable: true, sender: .init(id: UUID().uuidString), content: .init(body: "Test"))
        let view = TextBasedRoomTimelineViewMock<TextRoomTimelineItem>()
        view.underlyingTimelineItem = timelineItem
        view.timelineStyle = .bubbles

        XCTAssertEqual(view.additionalWhitespaces, timestamp.count + 1)
    }

    func testTextRoomTimelineItemWhitespaceEndPlain() {
        let timelineItem = TextRoomTimelineItem(id: .init(timelineID: UUID().uuidString), timestamp: "Now", isOutgoing: true, isEditable: true, sender: .init(id: UUID().uuidString), content: .init(body: "Test"))
        let view = TextBasedRoomTimelineViewMock<TextRoomTimelineItem>()
        view.underlyingTimelineItem = timelineItem
        view.timelineStyle = .plain

        XCTAssertEqual(view.additionalWhitespaces, 0)
    }

    func testTextRoomTimelineItemWhitespaceEndWithEdit() {
        let timestamp = "Now"
        var timelineItem = TextRoomTimelineItem(id: .init(timelineID: UUID().uuidString), timestamp: timestamp, isOutgoing: true, isEditable: true, sender: .init(id: UUID().uuidString), content: .init(body: "Test"))
        timelineItem.properties.isEdited = true
        let editedCount = L10n.commonEditedSuffix.count
        let view = TextBasedRoomTimelineViewMock<TextRoomTimelineItem>()
        view.underlyingTimelineItem = timelineItem
        view.timelineStyle = .bubbles

        XCTAssertEqual(view.additionalWhitespaces, timestamp.count + editedCount + 2)
    }

    func testTextRoomTimelineItemWhitespaceEndWithEditAndAlert() {
        let timestamp = "Now"
        var timelineItem = TextRoomTimelineItem(id: .init(timelineID: UUID().uuidString), timestamp: timestamp, isOutgoing: true, isEditable: true, sender: .init(id: UUID().uuidString), content: .init(body: "Test"))
        timelineItem.properties.isEdited = true
        timelineItem.properties.deliveryStatus = .sendingFailed
        let editedCount = L10n.commonEditedSuffix.count
        let view = TextBasedRoomTimelineViewMock<TextRoomTimelineItem>()
        view.underlyingTimelineItem = timelineItem
        view.timelineStyle = .bubbles

        XCTAssertEqual(view.additionalWhitespaces, timestamp.count + editedCount + 5)
    }
}

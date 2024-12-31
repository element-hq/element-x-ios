//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import MatrixRustSDK

import XCTest

@MainActor
class TimelineItemFactoryTests: XCTestCase {
    func testCallInvite() async {
        let ownUserID = "@alice:matrix.org"
        let senderUserID = "@bob:matrix.org"

        let factory = RoomTimelineItemFactory(userID: ownUserID,
                                              attributedStringBuilder: AttributedStringBuilder(mentionBuilder: MentionBuilder()),
                                              stateEventStringBuilder: RoomStateEventStringBuilder(userID: ownUserID))
        
        let eventTimelineItem = EventTimelineItem.mockCallInvite(sender: senderUserID)
        
        let eventTimelineItemProxy = EventTimelineItemProxy(item: eventTimelineItem, uniqueID: .init(id: "0"))
        
        let item = factory.buildTimelineItem(for: eventTimelineItemProxy, isDM: false)
        
        guard let item = item as? CallInviteRoomTimelineItem else {
            XCTFail("Incorrect item type")
            return
        }
        
        XCTAssertEqual(item.isReactable, false)
        XCTAssertEqual(item.canBeRepliedTo, false)
        XCTAssertEqual(item.isEditable, false)
        XCTAssertEqual(item.sender, TimelineItemSender(id: senderUserID))
        XCTAssertEqual(item.properties.isEdited, false)
        XCTAssertEqual(item.properties.reactions, [])
        XCTAssertEqual(item.properties.deliveryStatus, nil)
    }
}

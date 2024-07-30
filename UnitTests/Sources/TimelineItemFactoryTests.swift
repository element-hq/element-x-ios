//
// Copyright 2024 New Vector Ltd
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

@MainActor
class TimelineItemFactoryTests: XCTestCase {
    func testCallInvite() async {
        let ownUserID = "@alice:matrix.org"
        let senderUserID = "@bob:matrix.org"

        let factory = RoomTimelineItemFactory(userID: ownUserID,
                                              encryptionAuthenticityEnabled: true,
                                              attributedStringBuilder: AttributedStringBuilder(mentionBuilder: MentionBuilder()),
                                              stateEventStringBuilder: RoomStateEventStringBuilder(userID: ownUserID))
        
        let eventTimelineItem = EventTimelineItemSDKMock()
        eventTimelineItem.isOwnReturnValue = true
        eventTimelineItem.timestampReturnValue = 0
        eventTimelineItem.isEditableReturnValue = false
        eventTimelineItem.canBeRepliedToReturnValue = false
        eventTimelineItem.senderReturnValue = senderUserID
        eventTimelineItem.senderProfileReturnValue = .pending
        
        let timelineItemContent = TimelineItemContentSDKMock()
        timelineItemContent.kindReturnValue = .callInvite
        eventTimelineItem.contentReturnValue = timelineItemContent
        
        let eventTimelineItemProxy = EventTimelineItemProxy(item: eventTimelineItem, id: "0")
        
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

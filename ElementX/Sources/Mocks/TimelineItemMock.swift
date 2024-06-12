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

import Combine
import Foundation
import LoremSwiftum
import MatrixRustSDK

enum TimelineItemFixtures {
    static var callInviteTimelineItem: TimelineItem {
        let eventTimelineItem = EventTimelineItemSDKMock()
        eventTimelineItem.isOwnReturnValue = true
        eventTimelineItem.timestampReturnValue = 0
        eventTimelineItem.isEditableReturnValue = false
        eventTimelineItem.canBeRepliedToReturnValue = false
        eventTimelineItem.senderReturnValue = "@bob:matrix.org"
        eventTimelineItem.senderProfileReturnValue = .pending
        
        let timelineItemContent = TimelineItemContentSDKMock()
        timelineItemContent.kindReturnValue = .callInvite
        eventTimelineItem.contentReturnValue = timelineItemContent
        
        let timelineItem = TimelineItemSDKMock()
        timelineItem.asEventReturnValue = eventTimelineItem
        
        return timelineItem
    }
    
    static var messageTimelineItem: TimelineItem {
        let eventTimelineItem = EventTimelineItemSDKMock()
        eventTimelineItem.eventIdReturnValue = UUID().uuidString
        eventTimelineItem.isOwnReturnValue = true
        eventTimelineItem.timestampReturnValue = 0
        eventTimelineItem.isEditableReturnValue = false
        eventTimelineItem.canBeRepliedToReturnValue = false
        eventTimelineItem.senderReturnValue = "@bob:matrix.org"
        eventTimelineItem.senderProfileReturnValue = .pending
        eventTimelineItem.reactionsReturnValue = []
        eventTimelineItem.readReceiptsReturnValue = [:]
        
        let timelineItemContent = TimelineItemContentSDKMock()
        
        timelineItemContent.kindReturnValue = .message
            
        let message = MessageSDKMock()
        
        let textMessageContent = TextMessageContent(body: Lorem.sentences(Int.random(in: 1...5)), formatted: nil)
        message.msgtypeReturnValue = .text(content: textMessageContent)
        message.isThreadedReturnValue = false
        message.isEditedReturnValue = false
        
        timelineItemContent.asMessageReturnValue = message
        
        eventTimelineItem.contentReturnValue = timelineItemContent
        
        let timelineItem = TimelineItemSDKMock()
        timelineItem.asEventReturnValue = eventTimelineItem
        timelineItem.uniqueIdReturnValue = UUID().uuidString
        
        return timelineItem
    }
}

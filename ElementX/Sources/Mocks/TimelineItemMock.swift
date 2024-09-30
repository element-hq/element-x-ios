//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
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

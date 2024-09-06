//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

struct EventTimelineItemSDKMockConfiguration {
    var eventID: String = UUID().uuidString
}

extension EventTimelineItemSDKMock {
    convenience init(configuration: EventTimelineItemSDKMockConfiguration) {
        self.init()
        eventIdReturnValue = configuration.eventID
        isOwnReturnValue = false
        timestampReturnValue = 0
        isEditableReturnValue = false
        canBeRepliedToReturnValue = false
        senderReturnValue = ""
        senderProfileReturnValue = .pending
        
        let timelineItemContent = TimelineItemContentSDKMock()
        timelineItemContent.kindReturnValue = .redactedMessage
        contentReturnValue = timelineItemContent
    }
}

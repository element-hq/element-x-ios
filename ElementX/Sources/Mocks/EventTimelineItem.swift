//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import LoremSwiftum
import MatrixRustSDK

struct EventTimelineItemSDKMockConfiguration {
    var eventID: String = UUID().uuidString
    var sender = ""
    var isOwn = false
    var content: TimelineItemContent = .redactedMessage
}

extension EventTimelineItem {
    init(configuration: EventTimelineItemSDKMockConfiguration) {
        self.init(isRemote: true,
                  eventOrTransactionId: .eventId(eventId: configuration.eventID),
                  sender: configuration.sender,
                  senderProfile: .pending,
                  isOwn: configuration.isOwn,
                  isEditable: false,
                  content: configuration.content,
                  timestamp: 0,
                  reactions: [],
                  localSendState: nil,
                  localCreatedAt: nil,
                  readReceipts: [:],
                  origin: nil,
                  canBeRepliedTo: false,
                  lazyProvider: LazyTimelineItemProviderSDKMock())
    }
    
    static var mockMessage: EventTimelineItem {
        let body = Lorem.sentences(Int.random(in: 1...5))
        let messageType = MessageType.text(content: .init(body: body, formatted: nil))
        
        let content = TimelineItemContent.message(content: .init(msgType: messageType,
                                                                 body: body,
                                                                 inReplyTo: nil,
                                                                 threadRoot: nil,
                                                                 isEdited: false,
                                                                 mentions: nil))
        
        return .init(configuration: .init(content: content))
    }
    
    static func mockCallInvite(sender: String) -> EventTimelineItem {
        .init(configuration: .init(sender: sender, content: .callInvite))
    }
}

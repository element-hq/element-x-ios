//
// Copyright 2025 Element Creations Ltd.
// Copyright 2024-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import LoremSwiftum
import MatrixRustSDK
import MatrixRustSDKMocks

struct EventTimelineItemSDKMockConfiguration {
    var eventID: String = UUID().uuidString
    var sender = ""
    var senderProfile: ProfileDetails?
    var forwarder: String?
    var forwarderProfile: ProfileDetails?
    var isOwn = false
    var content: TimelineItemContent = .msgLike(content: .init(kind: .redacted,
                                                               reactions: [],
                                                               inReplyTo: nil,
                                                               threadRoot: nil,
                                                               threadSummary: nil))
}

extension EventTimelineItem {
    init(configuration: EventTimelineItemSDKMockConfiguration) {
        self.init(isRemote: true,
                  eventOrTransactionId: .eventId(eventId: configuration.eventID),
                  sender: configuration.sender,
                  senderProfile: configuration.senderProfile ?? .pending,
                  forwarder: configuration.forwarder,
                  forwarderProfile: configuration.forwarderProfile,
                  isOwn: configuration.isOwn,
                  isEditable: false,
                  content: configuration.content,
                  timestamp: 0,
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
        
        let content = TimelineItemContent.msgLike(content: .init(kind: .message(content: .init(msgType: messageType,
                                                                                               body: body,
                                                                                               isEdited: false,
                                                                                               mentions: nil)),
                                                                 reactions: [],
                                                                 inReplyTo: nil,
                                                                 threadRoot: nil,
                                                                 threadSummary: nil))
        
        return .init(configuration: .init(content: content))
    }
    
    static func mockCallInvite(sender: String) -> EventTimelineItem {
        .init(configuration: .init(sender: sender, content: .callInvite))
    }
}

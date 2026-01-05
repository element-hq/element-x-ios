//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRustSDK
import MatrixRustSDKMocks

struct NotificationItemProxyMockConfiguration {
    var event: NotificationEvent? = {
        // This is likely the most common notification kind
        // So it's also the best to use as a default test
        let messageType = MessageType.text(content: TextMessageContent(body: "Hello world!", formatted: nil))
        let messageLikeContent = MessageLikeEventContent.roomMessage(messageType: messageType, inReplyToEventId: nil)
        let event = TimelineEventSDKMock()
        event.eventIdUnderlyingReturnValue = UUID().uuidString
        event.contentReturnValue = .messageLike(content: messageLikeContent)
        return .timeline(event: event)
    }()
    
    var senderID: String = UUID().uuidString
    var roomID: String = UUID().uuidString
    var receiverID: String = UUID().uuidString
    var senderDisplayName: String?
    var senderAvatarMediaSource: MediaSourceProxy?
    var roomAvatarMediaSource: MediaSourceProxy?
    var roomDisplayName: String
    var roomJoinedMembers = 2
    var isRoomDirect = false
    var isRoomPrivate = false
    var isNoisy = false
    var hasMention = false
    var threadRootEventID: String?
}

extension NotificationItemProxyMock {
    convenience init(_ configuration: NotificationItemProxyMockConfiguration) {
        self.init()
        event = configuration.event
        underlyingSenderID = configuration.senderID
        underlyingRoomID = configuration.roomID
        underlyingReceiverID = configuration.receiverID
        senderDisplayName = configuration.senderDisplayName
        roomAvatarMediaSource = configuration.roomAvatarMediaSource
        underlyingRoomDisplayName = configuration.roomDisplayName
        underlyingRoomJoinedMembers = configuration.roomJoinedMembers
        underlyingIsRoomDirect = configuration.isRoomDirect
        underlyingIsRoomPrivate = configuration.isRoomPrivate
        underlyingIsNoisy = configuration.isNoisy
        underlyingHasMention = configuration.hasMention
        threadRootEventID = configuration.threadRootEventID
    }
}

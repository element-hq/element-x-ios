//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation
import MatrixRustSDK
import UserNotifications

struct NotificationItemProxy: NotificationItemProxyProtocol {
    let notificationItem: NotificationItem
    let eventID: String
    let receiverID: String
    let roomID: String
    
    let notificationSenderDisplayInfo: NotificationSenderDisplayInfo?

    var event: NotificationEvent? {
        notificationItem.event
    }

    var senderDisplayName: String? {
        notificationSenderDisplayInfo?.name ?? notificationItem.senderInfo.displayName
    }

    var senderID: String {
        switch notificationItem.event {
        case .timeline(let event):
            return event.senderId()
        case .invite(let senderID):
            return senderID
        }
    }

    var roomDisplayName: String {
        isRoomOneToOne ? (notificationSenderDisplayInfo?.name ?? notificationItem.roomInfo.displayName) : notificationItem.roomInfo.displayName
    }
    
    var isRoomOneToOne: Bool {
        isRoomDirect || roomJoinedMembers <= 2
    }

    var isRoomDirect: Bool {
        notificationItem.roomInfo.isDirect
    }

    var roomJoinedMembers: Int {
        Int(notificationItem.roomInfo.joinedMembersCount)
    }

    var isNoisy: Bool {
        notificationItem.isNoisy ?? false
    }
    
    var hasMention: Bool {
        notificationItem.hasMention ?? false
    }

    var senderAvatarMediaSource: MediaSourceProxy? {
        if let senderAvatarURLString = notificationSenderDisplayInfo?.avatarUrl ?? notificationItem.senderInfo.avatarUrl,
           let senderAvatarURL = URL(string: senderAvatarURLString) {
            return MediaSourceProxy(url: senderAvatarURL, mimeType: nil)
        }
        return nil
    }

    var roomAvatarMediaSource: MediaSourceProxy? {
        if let roomAvatarURLString = isRoomOneToOne ? (notificationSenderDisplayInfo?.avatarUrl ?? notificationItem.roomInfo.avatarUrl) : notificationItem.roomInfo.avatarUrl,
           let roomAvatarURL = URL(string: roomAvatarURLString) {
            return MediaSourceProxy(url: roomAvatarURL, mimeType: nil)
        }
        return nil
    }
}

struct NotificationSenderDisplayInfo {
    let name: String
    let avatarUrl: String?
}

struct EmptyNotificationItemProxy: NotificationItemProxyProtocol {
    let eventID: String

    var event: NotificationEvent? {
        nil
    }

    let roomID: String

    let receiverID: String

    var senderID: String { "" }

    var senderDisplayName: String? { nil }
    
    var roomDisplayName: String { "" }

    var isNoisy: Bool { false }

    var isRoomDirect: Bool { false }

    var senderAvatarMediaSource: MediaSourceProxy? { nil }

    var roomAvatarMediaSource: MediaSourceProxy? { nil }

    var roomJoinedMembers: Int { 0 }
    
    var hasMention: Bool { false }
}

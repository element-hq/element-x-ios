//
// Copyright 2022 New Vector Ltd
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

import Foundation
import MatrixRustSDK
import UserNotifications

struct NotificationItemProxy: NotificationItemProxyProtocol {
    let notificationItem: NotificationItem
    let eventID: String
    let receiverID: String
    let roomID: String

    var event: NotificationEvent? {
        notificationItem.event
    }

    var senderDisplayName: String? {
        notificationItem.senderInfo.displayName
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
        notificationItem.roomInfo.displayName
    }

    var roomCanonicalAlias: String? {
        notificationItem.roomInfo.canonicalAlias
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

    var senderAvatarMediaSource: MediaSourceProxy? {
        if let senderAvatarURLString = notificationItem.senderInfo.avatarUrl,
           let senderAvatarURL = URL(string: senderAvatarURLString) {
            return MediaSourceProxy(url: senderAvatarURL, mimeType: nil)
        }
        return nil
    }

    var roomAvatarMediaSource: MediaSourceProxy? {
        if let roomAvatarURLString = notificationItem.roomInfo.avatarUrl,
           let roomAvatarURL = URL(string: roomAvatarURLString) {
            return MediaSourceProxy(url: roomAvatarURL, mimeType: nil)
        }
        return nil
    }
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

    var senderAvatarURL: String? { nil }

    var roomDisplayName: String { "" }

    var roomCanonicalAlias: String? { nil }

    var roomAvatarURL: String? { nil }

    var isNoisy: Bool { false }

    var isRoomDirect: Bool { false }

    var isRoomEncrypted: Bool? { nil }

    var senderAvatarMediaSource: MediaSourceProxy? { nil }

    var roomAvatarMediaSource: MediaSourceProxy? { nil }

    var notificationIdentifier: String { "" }

    var roomJoinedMembers: Int { 0 }
}

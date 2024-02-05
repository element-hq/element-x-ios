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

struct RoomSummaryDetails {
    let id: String
    let name: String
    let isDirect: Bool
    let avatarURL: URL?
    let lastMessage: AttributedString?
    let lastMessageFormattedTimestamp: String?
    let isMarkedUnread: Bool
    let unreadMessagesCount: UInt
    let unreadMentionsCount: UInt
    let unreadNotificationsCount: UInt
    let notificationMode: RoomNotificationModeProxy?
    let canonicalAlias: String?
    let inviter: RoomMemberProxyProtocol?
    let hasOngoingCall: Bool
}

extension RoomSummaryDetails: CustomStringConvertible {
    var description: String { """
    RoomSummaryDetails: - id: \(id) \
    - isDirect: \(isDirect) \
    - unreadMessagesCount: \(unreadMessagesCount) \
    - unreadMentionsCount: \(unreadMentionsCount) \
    - unreadNotificationsCount: \(unreadNotificationsCount) \
    - notificationMode: \(notificationMode?.rawValue ?? "nil")
    """
    }
}

extension RoomSummaryDetails {
    init(id: String, settingsMode: RoomNotificationModeProxy, hasUnreadMessages: Bool, hasUnreadMentions: Bool, hasUnreadNotifications: Bool) {
        self.id = id
        let string = "\(settingsMode) - messages: \(hasUnreadMessages) - mentions: \(hasUnreadMentions) - notifications: \(hasUnreadNotifications)"
        name = string
        isDirect = true
        avatarURL = nil
        lastMessage = AttributedString(string)
        lastMessageFormattedTimestamp = "Now"
        isMarkedUnread = false
        unreadMessagesCount = hasUnreadMessages ? 1 : 0
        unreadMentionsCount = hasUnreadMentions ? 1 : 0
        unreadNotificationsCount = hasUnreadNotifications ? 1 : 0
        notificationMode = settingsMode
        canonicalAlias = nil
        inviter = nil
        hasOngoingCall = false
    }
}

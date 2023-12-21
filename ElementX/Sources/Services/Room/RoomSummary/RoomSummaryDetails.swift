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
    let unreadMessagesCount: UInt
    let unreadMentionsCount: UInt
    let notificationMode: RoomNotificationModeProxy?
    let canonicalAlias: String?
    let inviter: RoomMemberProxyProtocol?
    let hasOngoingCall: Bool
}

extension RoomSummaryDetails: CustomStringConvertible {
    var description: String {
        "RoomSummaryDetails: \(name) - id: \(id) - isDirect: \(isDirect) - unreadMessagesCount: \(unreadMessagesCount) - unreadMentionsCount: \(unreadMentionsCount) - notificationMode: \(notificationMode?.rawValue ?? "nil") - canonicalAlias: \(canonicalAlias ?? "nil") - inviter: \(inviter?.displayName ?? "nil") - hasOngoingCall: \(hasOngoingCall)"
    }
}

extension RoomSummaryDetails {
    init(id: String, settingsMode: RoomNotificationModeProxy, hasUnreadMessages: Bool, hasUnreadMentions: Bool) {
        self.id = id
        let string = "\(settingsMode) - hasUnreadMessages: \(hasUnreadMessages) - hasUnreadMentions: \(hasUnreadMentions)"
        name = string
        isDirect = true
        avatarURL = nil
        lastMessage = AttributedString(string)
        lastMessageFormattedTimestamp = "Now"
        unreadMessagesCount = hasUnreadMessages ? 1 : 0
        unreadMentionsCount = hasUnreadMentions ? 1 : 0
        notificationMode = settingsMode
        canonicalAlias = nil
        inviter = nil
        hasOngoingCall = false
    }
}

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

extension NotificationItemProxy {
    var requiresMediaProxy: Bool {
        false
        if avatarUrl != nil {
            return true
        }
        switch timelineItemProxy {
        case .event(let eventItem):
            guard eventItem.isMessage || eventItem.isRedacted else {
                // To be handled in the future
                return false
            }
            guard let message = eventItem.content.asMessage() else {
                fatalError("Only handled messages")
            }
            switch message.msgtype() {
            case .image:
                return true
            default:
                return false
            }
        case .virtual:
            return false
        case .other:
            return false
        }
    }

    func process(with message: Message,
                 senderId: String,
                 roomId: String,
                 mediaProxy: MediaProxyProtocol?) async throws -> UNMutableNotificationContent {
        switch message.msgtype() {
        case .text(content: let content):
            return try await processText(content: content,
                                         senderId: senderId,
                                         roomId: roomId,
                                         mediaProxy: mediaProxy)
        case .image(content: let content):
            return try await processImage(content: content,
                                          senderId: senderId,
                                          roomId: roomId,
                                          mediaProxy: mediaProxy)
        case .notice(content: let content):
            return try await processNotice(content: content,
                                           senderId: senderId,
                                           roomId: roomId,
                                           mediaProxy: mediaProxy)
        case .emote(content: let content):
            return try await processEmote(content: content,
                                          senderId: senderId,
                                          roomId: roomId,
                                          mediaProxy: mediaProxy)
        case .none:
            return UNMutableNotificationContent()
        }
    }

    // MARK: - Private

    private func processCommon(senderId: String,
                               roomId: String,
                               mediaProxy: MediaProxyProtocol?) async throws -> UNMutableNotificationContent {
        var notification = UNMutableNotificationContent()
        notification.title = title
        if let subtitle = subtitle {
            notification.subtitle = subtitle
        }
        notification.threadIdentifier = roomId
        notification.categoryIdentifier = NotificationConstants.Category.reply
        notification.sound = isNoisy ? UNNotificationSound(named: UNNotificationSoundName(rawValue: "message.caf")) : nil

        notification = try await notification.addSenderIcon(using: mediaProxy,
                                                            senderId: senderId,
                                                            senderName: title,
                                                            mediaSource: avatarMediaSource,
                                                            roomId: roomId)

        return notification
    }

    private func processText(content: TextMessageContent,
                             senderId: String,
                             roomId: String,
                             mediaProxy: MediaProxyProtocol?) async throws -> UNMutableNotificationContent {
        let notification = try await processCommon(senderId: senderId,
                                                   roomId: roomId,
                                                   mediaProxy: mediaProxy)
        notification.body = content.body

        return notification
    }

    private func processImage(content: ImageMessageContent,
                              senderId: String,
                              roomId: String,
                              mediaProxy: MediaProxyProtocol?) async throws -> UNMutableNotificationContent {
        var notification = try await processCommon(senderId: senderId,
                                                   roomId: roomId,
                                                   mediaProxy: mediaProxy)
        notification.body = content.body

        notification = try await notification.addImageAttachment(using: mediaProxy,
                                                                 mediaSource: .init(source: content.source))

        return notification
    }

    private func processNotice(content: NoticeMessageContent,
                               senderId: String,
                               roomId: String,
                               mediaProxy: MediaProxyProtocol?) async throws -> UNMutableNotificationContent {
        let notification = try await processCommon(senderId: senderId,
                                                   roomId: roomId,
                                                   mediaProxy: mediaProxy)
        notification.body = content.body

        return notification
    }

    private func processEmote(content: EmoteMessageContent,
                              senderId: String,
                              roomId: String,
                              mediaProxy: MediaProxyProtocol?) async throws -> UNMutableNotificationContent {
        let notification = try await processCommon(senderId: senderId,
                                                   roomId: roomId,
                                                   mediaProxy: mediaProxy)
        notification.body = content.body

        return notification
    }
}

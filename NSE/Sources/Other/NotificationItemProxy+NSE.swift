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
    var requiresMediaProvider: Bool {
        false
//        if avatarUrl != nil {
//            return true
//        }
//        switch timelineItemProxy {
//        case .event(let eventItem):
//            guard eventItem.isMessage else {
//                // To be handled in the future
//                return false
//            }
//            guard let message = eventItem.content.asMessage() else {
//                fatalError("Only handled messages")
//            }
//            switch message.msgtype() {
//            case .image, .video:
//                return true
//            default:
//                return false
//            }
//        case .virtual:
//            return false
//        case .other:
//            return false
//        }
    }

    /// Process the receiver item proxy
    /// - Parameters:
    ///   - receiverId: identifier of the user that has received the notification
    ///   - roomId: Room identifier
    ///   - mediaProvider: Media provider to process also media. May be passed nil to ignore media operations.
    /// - Returns: A notification content object if the notification should be displayed. Otherwise nil.
    func process(receiverId: String,
                 roomId: String,
                 mediaProvider: MediaProviderProtocol?) async throws -> UNMutableNotificationContent? {
//        switch timelineItemProxy {
//        case .event(let eventItem):
//            guard eventItem.isMessage else {
//                // To be handled in the future
//                return nil
//            }
//            guard let message = eventItem.content.asMessage() else {
//                fatalError("Item must be a message")
//            }
//
//            return try await process(message: message,
//                                     senderId: eventItem.sender,
//                                     roomId: roomId,
//                                     mediaProvider: mediaProvider)
//        case .virtual:
//            return nil
//        case .other:
//            return nil
//        }
        // For now we can't solve the sender ID nor get the type of message that we are displaying
        // so we are just going to process all of them as a text notification saying "Notification"
        let content = TextMessageContent(body: L10n.notification, formatted: nil)
        return try await processText(content: content, receiverId: receiverId, senderId: "undefined", roomId: roomId, mediaProvider: mediaProvider)
    }

    // MARK: - Private

    // MARK: Common

    private func process(message: Message,
                         receiverId: String,
                         senderId: String,
                         roomId: String,
                         mediaProvider: MediaProviderProtocol?) async throws -> UNMutableNotificationContent? {
        switch message.msgtype() {
        case .text(content: let content):
            return try await processText(content: content,
                                         receiverId: receiverId,
                                         senderId: senderId,
                                         roomId: roomId,
                                         mediaProvider: mediaProvider)
        case .image(content: let content):
            return try await processImage(content: content,
                                          receiverId: receiverId,
                                          senderId: senderId,
                                          roomId: roomId,
                                          mediaProvider: mediaProvider)
        case .audio(content: let content):
            return try await processAudio(content: content,
                                          receiverId: receiverId,
                                          senderId: senderId,
                                          roomId: roomId,
                                          mediaProvider: mediaProvider)
        case .video(content: let content):
            return try await processVideo(content: content,
                                          receiverId: receiverId,
                                          senderId: senderId,
                                          roomId: roomId,
                                          mediaProvider: mediaProvider)
        case .file(content: let content):
            return try await processFile(content: content,
                                         receiverId: receiverId,
                                         senderId: senderId,
                                         roomId: roomId,
                                         mediaProvider: mediaProvider)
        case .notice(content: let content):
            return try await processNotice(content: content,
                                           receiverId: receiverId,
                                           senderId: senderId,
                                           roomId: roomId,
                                           mediaProvider: mediaProvider)
        case .emote(content: let content):
            return try await processEmote(content: content,
                                          receiverId: receiverId,
                                          senderId: senderId,
                                          roomId: roomId,
                                          mediaProvider: mediaProvider)
        case .none:
            return nil
        }
    }

    private func processCommon(receiverId: String,
                               senderId: String,
                               roomId: String,
                               mediaProvider: MediaProviderProtocol?) async throws -> UNMutableNotificationContent {
        var notification = UNMutableNotificationContent()
        notification.receiverId = receiverId
        notification.title = title
        if let subtitle = subtitle {
            notification.subtitle = subtitle
        }
        // We can store the room identifier into the thread identifier since it's used for notifications
        // that belong to the same group
        notification.threadIdentifier = roomId
        notification.categoryIdentifier = NotificationConstants.Category.reply
        notification.sound = isNoisy ? UNNotificationSound(named: UNNotificationSoundName(rawValue: "message.caf")) : nil

        notification = try await notification.addSenderIcon(using: mediaProvider,
                                                            senderId: senderId,
                                                            senderName: title,
                                                            mediaSource: avatarMediaSource,
                                                            roomId: roomId)

        return notification
    }

    // MARK: Message Types

    private func processText(content: TextMessageContent,
                             receiverId: String,
                             senderId: String,
                             roomId: String,
                             mediaProvider: MediaProviderProtocol?) async throws -> UNMutableNotificationContent {
        let notification = try await processCommon(receiverId: receiverId,
                                                   senderId: senderId,
                                                   roomId: roomId,
                                                   mediaProvider: mediaProvider)
        notification.body = content.body

        return notification
    }

    private func processImage(content: ImageMessageContent,
                              receiverId: String,
                              senderId: String,
                              roomId: String,
                              mediaProvider: MediaProviderProtocol?) async throws -> UNMutableNotificationContent {
        var notification = try await processCommon(receiverId: receiverId,
                                                   senderId: senderId,
                                                   roomId: roomId,
                                                   mediaProvider: mediaProvider)
        notification.body = "📷 " + content.body

        notification = try await notification.addMediaAttachment(using: mediaProvider,
                                                                 mediaSource: .init(source: content.source, mimeType: content.info?.mimetype))

        return notification
    }

    private func processVideo(content: VideoMessageContent,
                              receiverId: String,
                              senderId: String,
                              roomId: String,
                              mediaProvider: MediaProviderProtocol?) async throws -> UNMutableNotificationContent {
        var notification = try await processCommon(receiverId: receiverId,
                                                   senderId: senderId,
                                                   roomId: roomId,
                                                   mediaProvider: mediaProvider)
        notification.body = "📹 " + content.body

        notification = try await notification.addMediaAttachment(using: mediaProvider,
                                                                 mediaSource: .init(source: content.source, mimeType: content.info?.mimetype))

        return notification
    }

    private func processFile(content: FileMessageContent,
                             receiverId: String,
                             senderId: String,
                             roomId: String,
                             mediaProvider: MediaProviderProtocol?) async throws -> UNMutableNotificationContent {
        let notification = try await processCommon(receiverId: receiverId,
                                                   senderId: senderId,
                                                   roomId: roomId,
                                                   mediaProvider: mediaProvider)
        notification.body = "📄 " + content.body

        return notification
    }

    private func processNotice(content: NoticeMessageContent,
                               receiverId: String,
                               senderId: String,
                               roomId: String,
                               mediaProvider: MediaProviderProtocol?) async throws -> UNMutableNotificationContent {
        let notification = try await processCommon(receiverId: receiverId,
                                                   senderId: senderId,
                                                   roomId: roomId,
                                                   mediaProvider: mediaProvider)
        notification.body = "❕ " + content.body

        return notification
    }

    private func processEmote(content: EmoteMessageContent,
                              receiverId: String,
                              senderId: String,
                              roomId: String,
                              mediaProvider: MediaProviderProtocol?) async throws -> UNMutableNotificationContent {
        let notification = try await processCommon(receiverId: receiverId,
                                                   senderId: senderId,
                                                   roomId: roomId,
                                                   mediaProvider: mediaProvider)
        notification.body = "🫥 " + content.body

        return notification
    }

    private func processAudio(content: AudioMessageContent,
                              receiverId: String,
                              senderId: String,
                              roomId: String,
                              mediaProvider: MediaProviderProtocol?) async throws -> UNMutableNotificationContent {
        let notification = try await processCommon(receiverId: receiverId,
                                                   senderId: senderId,
                                                   roomId: roomId,
                                                   mediaProvider: mediaProvider)
        notification.body = "🔊 " + content.body

        return notification
    }
}

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
import UserNotifications

import MatrixRustSDK

protocol NotificationItemProxyProtocol {
    var event: TimelineEventProxyProtocol { get }

    var roomID: String { get }

    var senderDisplayName: String? { get }

    var senderAvatarURL: String? { get }

    var roomDisplayName: String { get }

    var roomAvatarURL: String? { get }

    var isNoisy: Bool { get }

    var isDirect: Bool { get }

    var isEncrypted: Bool { get }

    var mediaSource: MediaSourceProxy? { get }
}

struct NotificationItemProxy: NotificationItemProxyProtocol {
    let notificationItem: NotificationItem

    var event: TimelineEventProxyProtocol {
        TimelineEventProxy(timelineEvent: notificationItem.event)
    }

    var roomID: String {
        notificationItem.roomId
    }

    var senderDisplayName: String? {
        notificationItem.senderDisplayName
    }

    var senderAvatarURL: String? {
        notificationItem.senderAvatarUrl
    }

    var roomDisplayName: String {
        notificationItem.roomDisplayName
    }

    var roomAvatarURL: String? {
        notificationItem.roomAvatarUrl
    }

    var isNoisy: Bool {
        notificationItem.isNoisy
    }

    var isDirect: Bool {
        notificationItem.isDirect
    }

    var isEncrypted: Bool {
        notificationItem.isEncrypted
    }

    var mediaSource: MediaSourceProxy?
}

// The mock and the protocol are just temporary until we can handle
// and decrypt notifications both in background and in foreground
// but they should not be necessary in the future
struct MockNotificationItemProxy: NotificationItemProxyProtocol {
    let eventID: String

    var event: TimelineEventProxyProtocol {
        MockTimelineEventProxy(eventID: eventID)
    }

    let roomID: String

    var senderDisplayName: String? { nil }

    var senderAvatarURL: String? { nil }

    var roomDisplayName: String { "" }

    var roomAvatarURL: String? { nil }

    var isNoisy: Bool { false }

    var isDirect: Bool { false }

    var isEncrypted: Bool { false }

    var mediaSource: MediaSourceProxy? { nil }
}

extension NotificationItemProxyProtocol {
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
        if self is MockNotificationItemProxy {
            let content = TextMessageContent(body: L10n.notification, formatted: nil)
            return try await processText(content: content, receiverId: receiverId, senderId: "undefined", roomId: roomId, mediaProvider: mediaProvider)
        } else {
            switch event.type {
            case .none, .state:
                return nil
            case let .messageLike(content):
                switch content {
                case .roomMessage(messageType: let messageType):
                    switch messageType {
                    case .emote(content: let content):
                        return try await processEmote(content: content, receiverId: receiverId, senderId: event.senderID, roomId: roomId, mediaProvider: mediaProvider)
                    case .image(content: let content):
                        return try await processImage(content: content, receiverId: receiverId, senderId: event.senderID, roomId: roomId, mediaProvider: mediaProvider)
                    case .audio(content: let content):
                        return try await processAudio(content: content, receiverId: receiverId, senderId: event.senderID, roomId: roomId, mediaProvider: mediaProvider)
                    case .video(content: let content):
                        return try await processVideo(content: content, receiverId: receiverId, senderId: event.senderID, roomId: roomId, mediaProvider: mediaProvider)
                    case .file(content: let content):
                        return try await processFile(content: content, receiverId: receiverId, senderId: event.senderID, roomId: roomId, mediaProvider: mediaProvider)
                    case .notice(content: let content):
                        return try await processNotice(content: content, receiverId: receiverId, senderId: event.senderID, roomId: roomId, mediaProvider: mediaProvider)
                    case .text(content: let content):
                        return try await processText(content: content, receiverId: receiverId, senderId: event.senderID, roomId: roomId, mediaProvider: mediaProvider)
                    }
                case .callAnswer, .callInvite, .callHangup, .callCandidates, .keyVerificationReady, .keyVerificationStart, .keyVerificationCancel, .keyVerificationAccept, .keyVerificationKey, .keyVerificationMac, .keyVerificationDone, .reactionContent, .roomEncrypted, .roomRedaction, .sticker:
                    return nil
                }
            }
        }
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
        notification.receiverID = receiverId
        notification.title = roomDisplayName
        notification.subtitle = senderDisplayName ?? ""
        // We can store the room identifier into the thread identifier since it's used for notifications
        // that belong to the same group
        notification.threadIdentifier = roomId
        notification.categoryIdentifier = NotificationConstants.Category.reply
        notification.sound = isNoisy ? UNNotificationSound(named: UNNotificationSoundName(rawValue: "message.caf")) : nil
        let senderPrefix = senderDisplayName != nil ? "\(senderDisplayName ?? "") in " : ""
        let senderName = "\(senderPrefix)\(roomDisplayName)"

        notification = try await notification.addSenderIcon(using: mediaProvider,
                                                            senderId: senderId,
                                                            senderName: senderName,
                                                            mediaSource: mediaSource,
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

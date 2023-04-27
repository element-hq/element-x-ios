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

    var senderAvatarMediaSource: MediaSourceProxy? { get }

    var roomDisplayName: String { get }

    var roomAvatarMediaSource: MediaSourceProxy? { get }

    var isNoisy: Bool { get }

    var isDirect: Bool { get }

    var isEncrypted: Bool { get }
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

    var roomDisplayName: String {
        notificationItem.roomDisplayName
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

    var senderAvatarMediaSource: MediaSourceProxy? {
        if let senderAvatarURLString = notificationItem.senderAvatarUrl,
           let senderAvatarURL = URL(string: senderAvatarURLString) {
            return MediaSourceProxy(url: senderAvatarURL, mimeType: nil)
        }
        return nil
    }

    var roomAvatarMediaSource: MediaSourceProxy? {
        if let roomAvatarURLString = notificationItem.roomAvatarUrl,
           let roomAvatarURL = URL(string: roomAvatarURLString) {
            return MediaSourceProxy(url: roomAvatarURL, mimeType: nil)
        }
        return nil
    }
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

    var senderAvatarMediaSource: MediaSourceProxy? { nil }

    var roomAvatarMediaSource: MediaSourceProxy? { nil }
}

extension NotificationItemProxyProtocol {
    var requiresMediaProvider: Bool {
        if senderAvatarMediaSource != nil || roomAvatarMediaSource != nil {
            return true
        }
        switch event.type {
        case .state, .none:
            return false
        case let .messageLike(content):
            switch content {
            case let .roomMessage(messageType):
                switch messageType {
                case .image, .video:
                    return true
                default:
                    return false
                }
            default:
                return false
            }
        }
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
        if self is MockNotificationItemProxy {
            return processMock(receiverId: receiverId, roomId: roomId)
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
                default:
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

    // To be removed once we don't need the mock anymore
    private func processMock(receiverId: String,
                             roomId: String) -> UNMutableNotificationContent {
        let notification = UNMutableNotificationContent()
        notification.receiverID = receiverId
        notification.title = InfoPlistReader(bundle: .app).bundleDisplayName
        notification.body = L10n.notification
        notification.threadIdentifier = roomId
        notification.categoryIdentifier = NotificationConstants.Category.reply
        notification.sound = isNoisy ? UNNotificationSound(named: UNNotificationSoundName(rawValue: "message.caf")) : nil
        return notification
    }

    private func processCommon(receiverId: String,
                               senderId: String,
                               roomId: String,
                               mediaProvider: MediaProviderProtocol?) async throws -> UNMutableNotificationContent {
        var notification = UNMutableNotificationContent()
        notification.receiverID = receiverId
        // These are fallbacks since the senderIcon also sets the title and the subtitle
        notification.title = senderDisplayName ?? roomDisplayName
        if notification.title != roomDisplayName {
            notification.subtitle = roomDisplayName
        }
        // We can store the room identifier into the thread identifier since it's used for notifications
        // that belong to the same group
        notification.threadIdentifier = roomId
        notification.categoryIdentifier = NotificationConstants.Category.reply
        notification.sound = isNoisy ? UNNotificationSound(named: UNNotificationSoundName(rawValue: "message.caf")) : nil

        let senderName = senderDisplayName ?? roomDisplayName
        var groupName: String?
        var mediaSource: MediaSourceProxy?
        if !isDirect {
            groupName = senderName != roomDisplayName ? roomDisplayName : nil
            mediaSource = roomAvatarMediaSource
        } else {
            mediaSource = senderAvatarMediaSource
        }

        notification = try await notification.addSenderIcon(using: mediaProvider,
                                                            senderId: senderId,
                                                            receiverId: receiverId,
                                                            senderName: senderName,
                                                            groupName: groupName,
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

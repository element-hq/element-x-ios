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

import CryptoKit
import Foundation
import UserNotifications

import MatrixRustSDK

protocol NotificationItemProxyProtocol {
    var event: TimelineEventProxyProtocol { get }

    var roomID: String { get }

    var receiverID: String { get }

    var senderDisplayName: String? { get }

    var senderAvatarMediaSource: MediaSourceProxy? { get }

    var roomDisplayName: String { get }

    var roomAvatarMediaSource: MediaSourceProxy? { get }

    var isNoisy: Bool { get }

    var isDirect: Bool { get }

    var isEncrypted: Bool { get }
}

extension NotificationItemProxyProtocol {
    var id: String? {
        let identifiers = receiverID + roomID + event.eventID
        guard let data = identifiers.data(using: .utf8) else {
            return nil
        }
        let digest = SHA256.hash(data: data)
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }
}

struct NotificationItemProxy: NotificationItemProxyProtocol {
    let notificationItem: NotificationItem
    let receiverID: String

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

    let receiverID: String

    var senderDisplayName: String? { nil }

    var senderAvatarURL: String? { nil }

    var roomDisplayName: String { "" }

    var roomAvatarURL: String? { nil }

    var isNoisy: Bool { false }

    var isDirect: Bool { false }

    var isEncrypted: Bool { false }

    var senderAvatarMediaSource: MediaSourceProxy? { nil }

    var roomAvatarMediaSource: MediaSourceProxy? { nil }

    var notificationIdentifier: String { "" }
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
                case .image, .video, .audio:
                    return true
                default:
                    return false
                }
            default:
                return false
            }
        }
    }

    // swiftlint: disable cyclomatic_complexity
    /// Process the receiver item proxy
    /// - Parameters:
    ///   - receiverId: identifier of the user that has received the notification
    ///   - roomId: Room identifier
    ///   - mediaProvider: Media provider to process also media. May be passed nil to ignore media operations.
    /// - Returns: A notification content object if the notification should be displayed. Otherwise nil.
    func process(mediaProvider: MediaProviderProtocol?) async throws -> UNMutableNotificationContent? {
        if self is MockNotificationItemProxy {
            return processMock()
        } else {
            switch event.type {
            case .none, .state:
                return nil
            case let .messageLike(content):
                switch content {
                case .roomMessage(messageType: let messageType):
                    switch messageType {
                    case .emote(content: let content):
                        return try await processEmote(content: content, mediaProvider: mediaProvider)
                    case .image(content: let content):
                        return try await processImage(content: content, mediaProvider: mediaProvider)
                    case .audio(content: let content):
                        return try await processAudio(content: content, mediaProvider: mediaProvider)
                    case .video(content: let content):
                        return try await processVideo(content: content, mediaProvider: mediaProvider)
                    case .file(content: let content):
                        return try await processFile(content: content, mediaProvider: mediaProvider)
                    case .notice(content: let content):
                        return try await processNotice(content: content, mediaProvider: mediaProvider)
                    case .text(content: let content):
                        return try await processText(content: content, mediaProvider: mediaProvider)
                    }
                default:
                    return nil
                }
            }
        }
    }
    
    // swiftlint: enable cyclomatic_complexity

    // MARK: - Private

    // To be removed once we don't need the mock anymore
    private func processMock() -> UNMutableNotificationContent {
        let notification = UNMutableNotificationContent()
        notification.receiverID = receiverID
        notification.roomID = roomID
        notification.eventID = event.eventID
        notification.notificationID = id
        notification.title = InfoPlistReader(bundle: .app).bundleDisplayName
        notification.body = L10n.notification
        notification.threadIdentifier = roomID
        notification.categoryIdentifier = NotificationConstants.Category.reply
        notification.sound = isNoisy ? UNNotificationSound(named: UNNotificationSoundName(rawValue: "message.caf")) : nil
        return notification
    }

    private func processCommon(mediaProvider: MediaProviderProtocol?) async throws -> UNMutableNotificationContent {
        var notification = UNMutableNotificationContent()
        notification.receiverID = receiverID
        notification.roomID = roomID
        notification.eventID = event.eventID
        notification.notificationID = id
        notification.title = senderDisplayName ?? roomDisplayName
        if notification.title != roomDisplayName {
            notification.subtitle = roomDisplayName
        }
        // We can store the room identifier into the thread identifier since it's used for notifications
        // that belong to the same group
        notification.threadIdentifier = roomID
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
                                                            senderId: event.senderID,
                                                            receiverId: receiverID,
                                                            senderName: senderName,
                                                            groupName: groupName,
                                                            mediaSource: mediaSource,
                                                            roomId: roomID)
        return notification
    }

    // MARK: Message Types

    private func processText(content: TextMessageContent,
                             mediaProvider: MediaProviderProtocol?) async throws -> UNMutableNotificationContent {
        let notification = try await processCommon(mediaProvider: mediaProvider)
        notification.body = content.body

        return notification
    }

    private func processImage(content: ImageMessageContent,
                              mediaProvider: MediaProviderProtocol?) async throws -> UNMutableNotificationContent {
        var notification = try await processCommon(mediaProvider: mediaProvider)
        notification.body = "📷 " + content.body

        notification = await notification.addMediaAttachment(using: mediaProvider,
                                                             mediaSource: .init(source: content.source,
                                                                                mimeType: content.info?.mimetype))

        return notification
    }

    private func processVideo(content: VideoMessageContent,
                              mediaProvider: MediaProviderProtocol?) async throws -> UNMutableNotificationContent {
        var notification = try await processCommon(mediaProvider: mediaProvider)
        notification.body = "📹 " + content.body

        notification = await notification.addMediaAttachment(using: mediaProvider,
                                                             mediaSource: .init(source: content.source,
                                                                                mimeType: content.info?.mimetype))

        return notification
    }

    private func processFile(content: FileMessageContent,
                             mediaProvider: MediaProviderProtocol?) async throws -> UNMutableNotificationContent {
        let notification = try await processCommon(mediaProvider: mediaProvider)
        notification.body = "📄 " + content.body

        return notification
    }

    private func processNotice(content: NoticeMessageContent,
                               mediaProvider: MediaProviderProtocol?) async throws -> UNMutableNotificationContent {
        let notification = try await processCommon(mediaProvider: mediaProvider)
        notification.body = "❕ " + content.body

        return notification
    }

    private func processEmote(content: EmoteMessageContent,
                              mediaProvider: MediaProviderProtocol?) async throws -> UNMutableNotificationContent {
        let notification = try await processCommon(mediaProvider: mediaProvider)
        notification.body = "🫥 " + content.body

        return notification
    }

    private func processAudio(content: AudioMessageContent,
                              mediaProvider: MediaProviderProtocol?) async throws -> UNMutableNotificationContent {
        var notification = try await processCommon(mediaProvider: mediaProvider)
        notification.body = "🔊 " + content.body

        notification = await notification.addMediaAttachment(using: mediaProvider,
                                                             mediaSource: .init(source: content.source,
                                                                                mimeType: content.info?.mimetype))

        return notification
    }
}

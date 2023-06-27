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

    var roomCanonicalAlias: String? { get }

    var roomAvatarMediaSource: MediaSourceProxy? { get }

    var isNoisy: Bool { get }

    var isDirect: Bool { get }

    /// Returns `true` if the event of the notification belongs to an encrypted room
    var isRoomEncrypted: Bool? { get }

    /// Returns `true` if was not possible to decrypt the notification content
    var isEncrypted: Bool { get }
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

    var roomCanonicalAlias: String? {
        notificationItem.roomCanonicalAlias
    }

    var isNoisy: Bool {
        notificationItem.isNoisy
    }

    var isDirect: Bool {
        notificationItem.isDirect
    }

    var isRoomEncrypted: Bool? {
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

    var isEncrypted: Bool {
        switch event.type {
        case .messageLike(let content):
            switch content {
            case .roomEncrypted:
                return true
            default:
                return false
            }
        default:
            return false
        }
    }
}

struct EmptyNotificationItemProxy: NotificationItemProxyProtocol {
    let eventID: String

    var event: TimelineEventProxyProtocol {
        MockTimelineEventProxy(eventID: eventID)
    }

    let roomID: String

    let receiverID: String

    var senderDisplayName: String? { nil }

    var senderAvatarURL: String? { nil }

    var roomDisplayName: String { "" }

    var roomCanonicalAlias: String? { nil }

    var roomAvatarURL: String? { nil }

    var isNoisy: Bool { false }

    var isDirect: Bool { false }

    var isRoomEncrypted: Bool? { nil }

    var senderAvatarMediaSource: MediaSourceProxy? { nil }

    var roomAvatarMediaSource: MediaSourceProxy? { nil }

    var notificationIdentifier: String { "" }

    var isEncrypted: Bool { false }
}

extension NotificationItemProxyProtocol {
    var baseMutableContent: UNMutableNotificationContent {
        let notification = UNMutableNotificationContent()
        notification.receiverID = receiverID
        notification.roomID = roomID
        notification.eventID = event.eventID
        notification.sound = isNoisy ? UNNotificationSound(named: UNNotificationSoundName(rawValue: "message.caf")) : nil
        // So that the UI groups notification that are received for the same room but also for the same user
        notification.threadIdentifier = "\(receiverID)\(roomID)"
        return notification
    }

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

    var icon: NotificationIcon {
        if isDirect {
            return NotificationIcon(mediaSource: senderAvatarMediaSource, groupInfo: nil)
        } else {
            return NotificationIcon(mediaSource: roomAvatarMediaSource,
                                    groupInfo: .init(name: roomDisplayName, id: roomID))
        }
    }

    /// Process the receiver item proxy
    /// - Parameters:
    ///   - receiverId: identifier of the user that has received the notification
    ///   - roomId: Room identifier
    ///   - mediaProvider: Media provider to process also media. May be passed nil to ignore media operations.
    /// - Returns: A notification content object if the notification should be displayed. Otherwise nil.
    func process(mediaProvider: MediaProviderProtocol?) async throws -> UNMutableNotificationContent {
        if self is EmptyNotificationItemProxy {
            return processEmpty()
        } else {
            switch event.type {
            case .none:
                return processEmpty()
            case let .state(content):
                return try await processStateEvent(content: content, mediaProvider: mediaProvider)
            case let .messageLike(content):
                switch content {
                case .roomMessage(messageType: let messageType):
                    return try await processRoomMessage(messageType: messageType, mediaProvider: mediaProvider)
                default:
                    return processEmpty()
                }
            }
        }
    }

    // MARK: - Private

    private func processStateEvent(content: StateEventContent, mediaProvider: MediaProviderProtocol?) async throws -> UNMutableNotificationContent {
        switch content {
        case let .roomMemberContent(userId, membershipState):
            switch membershipState {
            case .invite:
                if userId == receiverID {
                    return try await processInvited(mediaProvider: mediaProvider)
                } else {
                    return processEmpty()
                }
            default:
                return processEmpty()
            }
        default:
            return processEmpty()
        }
    }

    private func processInvited(mediaProvider: MediaProviderProtocol?) async throws -> UNMutableNotificationContent {
        var notification = baseMutableContent

        notification.categoryIdentifier = NotificationConstants.Category.invite

        let body: String
        if !isDirect {
            body = L10n.notificationRoomInviteBody
        } else {
            body = L10n.notificationInviteBody
        }

        notification = try await notification.addSenderIcon(using: mediaProvider,
                                                            senderID: event.senderID,
                                                            senderName: senderDisplayName ?? roomDisplayName,
                                                            icon: icon)
        notification.body = body
        
        return notification
    }

    private func processRoomMessage(messageType: MessageType, mediaProvider: MediaProviderProtocol?) async throws -> UNMutableNotificationContent {
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
        case .location:
            return processEmpty()
        }
    }

    private func processEmpty() -> UNMutableNotificationContent {
        let notification = baseMutableContent
        notification.title = InfoPlistReader(bundle: .app).bundleDisplayName
        notification.body = L10n.notification
        notification.categoryIdentifier = NotificationConstants.Category.message
        return notification
    }

    private func processCommon(mediaProvider: MediaProviderProtocol?) async throws -> UNMutableNotificationContent {
        var notification = baseMutableContent
        notification.title = senderDisplayName ?? roomDisplayName
        if notification.title != roomDisplayName {
            notification.subtitle = roomDisplayName
        }
        notification.categoryIdentifier = NotificationConstants.Category.message

        notification = try await notification.addSenderIcon(using: mediaProvider,
                                                            senderID: event.senderID,
                                                            senderName: senderDisplayName ?? roomDisplayName,
                                                            icon: icon)
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
        notification.body = L10n.commonEmote(senderDisplayName ?? roomDisplayName, content.body)

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

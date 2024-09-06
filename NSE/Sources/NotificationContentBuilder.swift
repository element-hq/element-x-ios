//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation
import MatrixRustSDK
import UserNotifications

struct NotificationContentBuilder {
    let messageEventStringBuilder: RoomMessageEventStringBuilder
    
    /// Process the given notification item proxy
    /// - Parameters:
    ///   - notificationItem: The notification item
    ///   - mediaProvider: Media provider to process also media. May be passed nil to ignore media operations.
    /// - Returns: A notification content object if the notification should be displayed. Otherwise nil.
    func content(for notificationItem: NotificationItemProxyProtocol, mediaProvider: MediaProviderProtocol?) async throws -> UNMutableNotificationContent {
        switch notificationItem.event {
        case .none:
            return processEmpty(notificationItem: notificationItem)
        case .invite:
            return try await processInvited(notificationItem: notificationItem, mediaProvider: mediaProvider)
        case .timeline(let event):
            guard let eventType = try? event.eventType() else {
                return processEmpty(notificationItem: notificationItem)
            }

            switch eventType {
            case let .messageLike(content):
                switch content {
                case .roomMessage(let messageType, _):
                    return try await processRoomMessage(notificationItem: notificationItem, messageType: messageType, mediaProvider: mediaProvider)
                case .poll(let question):
                    return try await processPollStartEvent(notificationItem: notificationItem, pollQuestion: question, mediaProvider: mediaProvider)
                case .callInvite:
                    return try await processCallInviteEvent(notificationItem: notificationItem, mediaProvider: mediaProvider)
                case .callNotify:
                    return try await processCallNotifyEvent(notificationItem: notificationItem, mediaProvider: mediaProvider)
                default:
                    return processEmpty(notificationItem: notificationItem)
                }
            case .state:
                return processEmpty(notificationItem: notificationItem)
            }
        }
    }

    // MARK: - Private
    
    func baseMutableContent(for notificationItem: NotificationItemProxyProtocol) -> UNMutableNotificationContent {
        let notification = UNMutableNotificationContent()
        notification.receiverID = notificationItem.receiverID
        notification.roomID = notificationItem.roomID
        notification.eventID = switch notificationItem.event {
        case .timeline(let event): event.eventId()
        case .invite, .none: nil
        }
        notification.sound = notificationItem.isNoisy ? UNNotificationSound(named: UNNotificationSoundName(rawValue: "message.caf")) : nil
        // So that the UI groups notification that are received for the same room but also for the same user
        // Removing the @ fixes an iOS bug where the notification crashes if the mute button is tapped
        notification.threadIdentifier = "\(notificationItem.receiverID)\(notificationItem.roomID)".replacingOccurrences(of: "@", with: "")
        return notification
    }
    
    private func processEmpty(notificationItem: NotificationItemProxyProtocol) -> UNMutableNotificationContent {
        let notification = baseMutableContent(for: notificationItem)
        notification.title = InfoPlistReader(bundle: .app).bundleDisplayName
        notification.body = L10n.notification
        notification.categoryIdentifier = NotificationConstants.Category.message
        return notification
    }

    private func processInvited(notificationItem: NotificationItemProxyProtocol, mediaProvider: MediaProviderProtocol?) async throws -> UNMutableNotificationContent {
        var notification = baseMutableContent(for: notificationItem)

        notification.categoryIdentifier = NotificationConstants.Category.invite

        let body: String
        if !notificationItem.isDM {
            body = L10n.notificationRoomInviteBody
        } else {
            body = L10n.notificationInviteBody
        }

        notification = try await notification.addSenderIcon(using: mediaProvider,
                                                            senderID: notificationItem.senderID,
                                                            senderName: notificationItem.senderDisplayName ?? notificationItem.roomDisplayName,
                                                            icon: icon(for: notificationItem))
        notification.body = body
        
        return notification
    }

    private func processRoomMessage(notificationItem: NotificationItemProxyProtocol, messageType: MessageType, mediaProvider: MediaProviderProtocol?) async throws -> UNMutableNotificationContent {
        var notification = try await processCommonRoomMessage(notificationItem: notificationItem, mediaProvider: mediaProvider)
        
        let displayName = notificationItem.senderDisplayName ?? notificationItem.roomDisplayName
        notification.body = String(messageEventStringBuilder.buildAttributedString(for: messageType, senderDisplayName: displayName).characters)
        
        switch messageType {
        case .image(content: let content):
            notification = await notification.addMediaAttachment(using: mediaProvider,
                                                                 mediaSource: .init(source: content.source,
                                                                                    mimeType: content.info?.mimetype))
        case .audio(content: let content):
            notification = await notification.addMediaAttachment(using: mediaProvider,
                                                                 mediaSource: .init(source: content.source,
                                                                                    mimeType: content.info?.mimetype))
        case .video(content: let content):
            notification = await notification.addMediaAttachment(using: mediaProvider,
                                                                 mediaSource: .init(source: content.source,
                                                                                    mimeType: content.info?.mimetype))
        default:
            break
        }
        
        return notification
    }

    private func processPollStartEvent(notificationItem: NotificationItemProxyProtocol, pollQuestion: String, mediaProvider: MediaProviderProtocol?) async throws -> UNMutableNotificationContent {
        let notification = try await processCommonRoomMessage(notificationItem: notificationItem, mediaProvider: mediaProvider)
        notification.body = L10n.commonPollSummary(pollQuestion)
        return notification
    }
    
    private func processCallInviteEvent(notificationItem: NotificationItemProxyProtocol, mediaProvider: MediaProviderProtocol?) async throws -> UNMutableNotificationContent {
        let notification = try await processCommonRoomMessage(notificationItem: notificationItem, mediaProvider: mediaProvider)
        notification.body = L10n.commonCallInvite
        return notification
    }
    
    private func processCallNotifyEvent(notificationItem: NotificationItemProxyProtocol, mediaProvider: MediaProviderProtocol?) async throws -> UNMutableNotificationContent {
        let notification = try await processCommonRoomMessage(notificationItem: notificationItem, mediaProvider: mediaProvider)
        notification.body = L10n.commonCallStarted
        return notification
    }

    private func processCommonRoomMessage(notificationItem: NotificationItemProxyProtocol, mediaProvider: MediaProviderProtocol?) async throws -> UNMutableNotificationContent {
        var notification = baseMutableContent(for: notificationItem)
        notification.title = notificationItem.senderDisplayName ?? notificationItem.roomDisplayName
        if notification.title != notificationItem.roomDisplayName {
            notification.subtitle = notificationItem.roomDisplayName
        }
        notification.categoryIdentifier = NotificationConstants.Category.message

        let senderName = if let displayName = notificationItem.senderDisplayName {
            notificationItem.hasMention ? L10n.notificationSenderMentionReply(displayName) : displayName
        } else {
            notificationItem.roomDisplayName
        }
        notification = try await notification.addSenderIcon(using: mediaProvider,
                                                            senderID: notificationItem.senderID,
                                                            senderName: senderName,
                                                            icon: icon(for: notificationItem))
        return notification
    }
    
    func icon(for notificationItem: NotificationItemProxyProtocol) -> NotificationIcon {
        if notificationItem.isDM {
            return NotificationIcon(mediaSource: notificationItem.senderAvatarMediaSource, groupInfo: nil)
        } else {
            return NotificationIcon(mediaSource: notificationItem.roomAvatarMediaSource,
                                    groupInfo: .init(name: notificationItem.roomDisplayName, id: notificationItem.roomID))
        }
    }
}

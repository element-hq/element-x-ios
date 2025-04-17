//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRustSDK
import UserNotifications

struct NotificationContentBuilder {
    let messageEventStringBuilder: RoomMessageEventStringBuilder
    let settings: CommonSettingsProtocol
    
    /// Process the given notification item proxy
    /// - Parameters:
    ///   - notificationItem: The notification item
    ///   - mediaProvider: Media provider to process also media. May be passed nil to ignore media operations.
    /// - Returns: A notification content object if the notification should be displayed. Otherwise nil.
    func process(notificationContent: UNMutableNotificationContent,
                 notificationItem: NotificationItemProxyProtocol,
                 mediaProvider: MediaProviderProtocol) async -> UNMutableNotificationContent {
        notificationContent.receiverID = notificationItem.receiverID
        notificationContent.roomID = notificationItem.roomID
        
        switch notificationItem.event {
        case .timeline(let event):
            notificationContent.eventID = event.eventId()
        case .invite, .none:
            notificationContent.eventID = nil
        }
        
        // So that the UI groups notification that are received for the same room but also for the same user
        // Removing the @ fixes an iOS bug where the notification crashes if the mute button is tapped
        notificationContent.threadIdentifier = "\(notificationItem.receiverID)\(notificationItem.roomID)".replacingOccurrences(of: "@", with: "")
        
        MXLog.info("isNoisy: \(notificationItem.isNoisy)")
        notificationContent.sound = notificationItem.isNoisy ? UNNotificationSound(named: UNNotificationSoundName(rawValue: "message.caf")) : nil
        
        switch notificationItem.event {
        case .none:
            return processEmpty(notificationContent)
        case .invite:
            return await processInvited(notificationContent: notificationContent,
                                        notificationItem: notificationItem,
                                        mediaProvider: mediaProvider)
        case .timeline(let event):
            guard let eventType = try? event.eventType(),
                  case let .messageLike(content) = eventType else {
                return processEmpty(notificationContent)
            }
            
            let notificationContent = await processMessageLike(notificationContent: notificationContent,
                                                               notificationItem: notificationItem,
                                                               mediaProvider: mediaProvider)
            
            switch content {
            case .roomMessage(let messageType, _):
                return await processRoomMessage(notificationContent: notificationContent,
                                                notificationItem: notificationItem,
                                                messageType: messageType,
                                                mediaProvider: mediaProvider)
            case .poll(let question):
                notificationContent.body = L10n.commonPollSummary(question)
                return notificationContent
            case .callInvite:
                notificationContent.body = L10n.commonUnsupportedCall
                return notificationContent
            case .callNotify:
                notificationContent.body = L10n.notificationIncomingCall
                return notificationContent
            default:
                return processEmpty(notificationContent)
            }
        }
    }

    // MARK: - Private
    
    private func processEmpty(_ notificationContent: UNMutableNotificationContent) -> UNMutableNotificationContent {
        notificationContent.title = InfoPlistReader(bundle: .app).bundleDisplayName
        notificationContent.body = L10n.notification
        notificationContent.categoryIdentifier = NotificationConstants.Category.message
        
        return notificationContent
    }

    private func processInvited(notificationContent: UNMutableNotificationContent,
                                notificationItem: NotificationItemProxyProtocol,
                                mediaProvider: MediaProviderProtocol) async -> UNMutableNotificationContent {
        notificationContent.categoryIdentifier = NotificationConstants.Category.invite

        let body: String
        if !notificationItem.isDM {
            body = L10n.notificationRoomInviteBody
        } else {
            body = L10n.notificationInviteBody
        }
        
        notificationContent.body = body
        
        do {
            return try await notificationContent.addSenderIcon(senderID: notificationItem.senderID,
                                                               senderName: notificationItem.senderDisplayName ?? notificationItem.roomDisplayName,
                                                               icon: icon(for: notificationItem),
                                                               forcePlaceholder: settings.hideInviteAvatars,
                                                               mediaProvider: mediaProvider)
        } catch {
            return notificationContent
        }
    }
    
    private func processMessageLike(notificationContent: UNMutableNotificationContent,
                                    notificationItem: NotificationItemProxyProtocol,
                                    mediaProvider: MediaProviderProtocol) async -> UNMutableNotificationContent {
        notificationContent.title = notificationItem.senderDisplayName ?? notificationItem.roomDisplayName
        if notificationContent.title != notificationItem.roomDisplayName {
            notificationContent.subtitle = notificationItem.roomDisplayName
        }
        notificationContent.categoryIdentifier = NotificationConstants.Category.message
        
        let senderName = if let displayName = notificationItem.senderDisplayName {
            notificationItem.hasMention ? L10n.notificationSenderMentionReply(displayName) : displayName
        } else {
            notificationItem.roomDisplayName
        }
        
        do {
            return try await notificationContent.addSenderIcon(senderID: notificationItem.senderID,
                                                               senderName: senderName,
                                                               icon: icon(for: notificationItem),
                                                               mediaProvider: mediaProvider)
        } catch {
            return notificationContent
        }
    }
    
    func icon(for notificationItem: NotificationItemProxyProtocol) -> NotificationIcon {
        if notificationItem.isDM {
            return NotificationIcon(mediaSource: notificationItem.senderAvatarMediaSource, groupInfo: nil)
        } else {
            return NotificationIcon(mediaSource: notificationItem.roomAvatarMediaSource,
                                    groupInfo: .init(name: notificationItem.roomDisplayName, id: notificationItem.roomID))
        }
    }

    private func processRoomMessage(notificationContent: UNMutableNotificationContent,
                                    notificationItem: NotificationItemProxyProtocol,
                                    messageType: MessageType,
                                    mediaProvider: MediaProviderProtocol) async -> UNMutableNotificationContent {
        let displayName = notificationItem.senderDisplayName ?? notificationItem.roomDisplayName
        notificationContent.body = String(messageEventStringBuilder.buildAttributedString(for: messageType, senderDisplayName: displayName, isOutgoing: false).characters)
        
        guard settings.timelineMediaVisibility == .always ||
            (settings.timelineMediaVisibility == .privateOnly && notificationItem.isRoomPrivate)
        else {
            return notificationContent
        }
        
        switch messageType {
        case .image(content: let content):
            await notificationContent.addMediaAttachment(using: mediaProvider,
                                                         mediaSource: .init(source: content.source,
                                                                            mimeType: content.info?.mimetype))
        case .audio(content: let content):
            await notificationContent.addMediaAttachment(using: mediaProvider,
                                                         mediaSource: .init(source: content.source,
                                                                            mimeType: content.info?.mimetype))
        case .video(content: let content):
            await notificationContent.addMediaAttachment(using: mediaProvider,
                                                         mediaSource: .init(source: content.source,
                                                                            mimeType: content.info?.mimetype))
        default:
            break
        }
        
        return notificationContent
    }
}

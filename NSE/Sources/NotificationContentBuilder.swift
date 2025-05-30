//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRustSDK
import UserNotifications

import Intents
import SwiftUI
import Version

struct NotificationContentBuilder {
    let messageEventStringBuilder: RoomMessageEventStringBuilder
    let userSession: NSEUserSession
    
    /// Process the given notification item proxy
    /// - Parameters:
    ///   - notificationItem: The notification item
    ///   - mediaProvider: Media provider to process also media. May be passed nil to ignore media operations.
    /// - Returns: A notification content object if the notification should be displayed. Otherwise nil.
    func process(notificationContent: inout UNMutableNotificationContent,
                 notificationItem: NotificationItemProxyProtocol,
                 mediaProvider: MediaProviderProtocol) async {
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
            processEmpty(&notificationContent)
        case .invite:
            await processInvited(notificationContent: &notificationContent,
                                 notificationItem: notificationItem,
                                 mediaProvider: mediaProvider)
        case .timeline(let event):
            guard let eventType = try? event.eventType(),
                  case let .messageLike(content) = eventType else {
                processEmpty(&notificationContent)
                return
            }
            
            await processMessageLike(notificationContent: &notificationContent,
                                     notificationItem: notificationItem,
                                     mediaProvider: mediaProvider)
            
            switch content {
            case .roomMessage(let messageType, _):
                await processRoomMessage(notificationContent: &notificationContent,
                                         notificationItem: notificationItem,
                                         messageType: messageType,
                                         mediaProvider: mediaProvider)
            case .poll(let question):
                notificationContent.body = L10n.commonPollSummary(question)
            case .callInvite:
                notificationContent.body = L10n.commonUnsupportedCall
            case .callNotify:
                notificationContent.body = L10n.notificationIncomingCall
            default:
                processEmpty(&notificationContent)
            }
        }
    }

    // MARK: - Private
    
    private func processEmpty(_ notificationContent: inout UNMutableNotificationContent) {
        notificationContent.title = InfoPlistReader(bundle: .app).bundleDisplayName
        notificationContent.body = L10n.notification
        notificationContent.categoryIdentifier = NotificationConstants.Category.message
    }

    private func processInvited(notificationContent: inout UNMutableNotificationContent,
                                notificationItem: NotificationItemProxyProtocol,
                                mediaProvider: MediaProviderProtocol) async {
        notificationContent.categoryIdentifier = NotificationConstants.Category.invite

        let body: String
        if !notificationItem.isDM {
            body = L10n.notificationRoomInviteBody
        } else {
            body = L10n.notificationInviteBody
        }
        
        notificationContent.body = body
        
        await addSenderIcon(notificationContent: &notificationContent,
                            senderID: notificationItem.senderID,
                            senderName: notificationItem.senderDisplayName ?? notificationItem.roomDisplayName,
                            icon: icon(for: notificationItem),
                            forcePlaceholder: userSession.inviteAvatarsVisibility == .off,
                            mediaProvider: mediaProvider)
    }
    
    private func processMessageLike(notificationContent: inout UNMutableNotificationContent,
                                    notificationItem: NotificationItemProxyProtocol,
                                    mediaProvider: MediaProviderProtocol) async {
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
        
        await addSenderIcon(notificationContent: &notificationContent,
                            senderID: notificationItem.senderID,
                            senderName: senderName,
                            icon: icon(for: notificationItem),
                            mediaProvider: mediaProvider)
    }
    
    private func icon(for notificationItem: NotificationItemProxyProtocol) -> NotificationIcon {
        if notificationItem.isDM {
            return NotificationIcon(mediaSource: notificationItem.senderAvatarMediaSource, groupInfo: nil)
        } else {
            return NotificationIcon(mediaSource: notificationItem.roomAvatarMediaSource,
                                    groupInfo: .init(name: notificationItem.roomDisplayName, id: notificationItem.roomID))
        }
    }

    private func processRoomMessage(notificationContent: inout UNMutableNotificationContent,
                                    notificationItem: NotificationItemProxyProtocol,
                                    messageType: MessageType,
                                    mediaProvider: MediaProviderProtocol) async {
        let displayName = notificationItem.senderDisplayName ?? notificationItem.roomDisplayName
        notificationContent.body = String(messageEventStringBuilder.buildAttributedString(for: messageType, senderDisplayName: displayName, isOutgoing: false).characters)
        
        let timelineMediaVisibility = await userSession.mediaPreviewVisibility
        guard timelineMediaVisibility == .on ||
            (timelineMediaVisibility == .private && notificationItem.isRoomPrivate)
        else {
            return
        }
        
        switch messageType {
        case .image(content: let content):
            await addMediaAttachment(notificationContent: &notificationContent,
                                     using: mediaProvider,
                                     mediaSource: .init(source: content.source,
                                                        mimeType: content.info?.mimetype))
        case .audio(content: let content):
            await addMediaAttachment(notificationContent: &notificationContent,
                                     using: mediaProvider,
                                     mediaSource: .init(source: content.source,
                                                        mimeType: content.info?.mimetype))
        case .video(content: let content):
            await addMediaAttachment(notificationContent: &notificationContent,
                                     using: mediaProvider,
                                     mediaSource: .init(source: content.source,
                                                        mimeType: content.info?.mimetype))
        default:
            break
        }
    }
    
    private func addMediaAttachment(notificationContent: inout UNMutableNotificationContent,
                                    using mediaProvider: MediaProviderProtocol,
                                    mediaSource: MediaSourceProxy) async {
        switch await mediaProvider.loadFileFromSource(mediaSource) {
        case .success(let file):
            do {
                guard let url = file.url else {
                    MXLog.error("Couldn't add media attachment: URL is nil")
                    return
                }
                
                let identifier = ProcessInfo.processInfo.globallyUniqueString
                let newURL = try FileManager.default.copyFileToTemporaryDirectory(file: url, with: "\(identifier).\(url.pathExtension)")
                let attachment = try UNNotificationAttachment(identifier: identifier,
                                                              url: newURL,
                                                              options: nil)
                
                notificationContent.attachments.append(attachment)
            } catch {
                MXLog.error("Couldn't add media attachment:: \(error)")
                return
            }
        case .failure(let error):
            MXLog.error("Couldn't load the file for media attachment: \(error)")
        }
    }

    private func addSenderIcon(notificationContent: inout UNMutableNotificationContent,
                               senderID: String,
                               senderName: String,
                               icon: NotificationIcon,
                               forcePlaceholder: Bool = false,
                               mediaProvider: MediaProviderProtocol) async {
        var fetchedImage: INImage?
        let image: INImage
        if !forcePlaceholder,
           let mediaSource = icon.mediaSource {
            switch await mediaProvider.loadThumbnailForSource(source: mediaSource, size: .init(width: 100, height: 100)) {
            case .success(let data):
                fetchedImage = INImage(imageData: data)
            case .failure(let error):
                MXLog.error("Couldn't add sender icon: \(error)")
            }
        }

        if let fetchedImage {
            image = fetchedImage
        } else if let data = await getPlaceholderAvatarImageData(name: icon.groupInfo?.name ?? senderName,
                                                                 id: icon.groupInfo?.id ?? senderID) {
            image = INImage(imageData: data)
        } else {
            image = INImage(named: "")
        }

        let senderHandle = INPersonHandle(value: senderID, type: .unknown)
        let sender = INPerson(personHandle: senderHandle,
                              nameComponents: nil,
                              displayName: senderName,
                              image: !icon.shouldDisplayAsGroup ? image : nil,
                              contactIdentifier: nil,
                              customIdentifier: nil)

        // These are required to show the group name as subtitle
        var speakableGroupName: INSpeakableString?
        var recipients: [INPerson]?
        if let groupInfo = icon.groupInfo {
            let meHandle = INPersonHandle(value: notificationContent.receiverID, type: .unknown)
            let me = INPerson(personHandle: meHandle, nameComponents: nil, displayName: nil, image: nil, contactIdentifier: nil, customIdentifier: nil, isMe: true)
            speakableGroupName = INSpeakableString(spokenPhrase: groupInfo.name)
            recipients = [sender, me]
        }

        let intent = INSendMessageIntent(recipients: recipients,
                                         outgoingMessageType: .outgoingMessageText,
                                         content: nil,
                                         speakableGroupName: speakableGroupName,
                                         conversationIdentifier: notificationContent.roomID,
                                         serviceName: nil,
                                         sender: sender,
                                         attachments: nil)
        if speakableGroupName != nil {
            intent.setImage(image, forParameterNamed: \.speakableGroupName)
        }

        // Use the intent to initialize the interaction.
        let interaction = INInteraction(intent: intent, response: nil)

        // Interaction direction is incoming because the user is
        // receiving this message.
        interaction.direction = .incoming

        // Donate the interaction before updating notification content.
        try? await interaction.donate()
        
        // Update notification content before displaying the
        // communication notification.
        if let updatedContent = try? notificationContent.updating(from: intent) {
            // swiftlint:disable:next force_cast
            let content = updatedContent.mutableCopy() as! UNMutableNotificationContent
            notificationContent = content
        }
    }

    @MainActor
    func getPlaceholderAvatarImageData(name: String, id: String) async -> Data? {
        // The version value is used in case the design of the placeholder is updated to force a replacement
        let prefix = "notification_placeholderV9"
        
        let fileName = "\(prefix)_\(name)_\(id).png"
        if let data = try? Data(contentsOf: URL.temporaryDirectory.appendingPathComponent(fileName)) {
            MXLog.info("Found existing notification icon placeholder")
            return data
        }
        
        MXLog.info("Generating notification icon placeholder")
        
        let data = Avatars.generatePlaceholderAvatarImageData(name: name, id: id, size: .init(width: 50, height: 50))
        
        if let data {
            do {
                // cache image data
                try FileManager.default.writeDataToTemporaryDirectory(data: data, fileName: fileName)
            } catch {
                MXLog.error("Could not store placeholder image")
                return data
            }
        }
        
        return data
    }
}

private struct NotificationIcon {
    struct GroupInfo {
        let name: String
        let id: String
    }
    
    let mediaSource: MediaSourceProxy?
    // Required as the key to set images for groups
    let groupInfo: GroupInfo?
    
    var shouldDisplayAsGroup: Bool {
        groupInfo != nil
    }
}

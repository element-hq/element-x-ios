//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import Intents
import SwiftUI
import UserNotifications

import Version

struct NotificationIcon {
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

extension UNNotificationContent {
    @objc var receiverID: String? {
        userInfo[NotificationConstants.UserInfoKey.receiverIdentifier] as? String
    }

    @objc var roomID: String? {
        userInfo[NotificationConstants.UserInfoKey.roomIdentifier] as? String
    }
    
    @objc var eventID: String? {
        userInfo[NotificationConstants.UserInfoKey.eventIdentifier] as? String
    }
}

extension UNMutableNotificationContent {
    override var receiverID: String? {
        get {
            userInfo[NotificationConstants.UserInfoKey.receiverIdentifier] as? String
        }
        set {
            userInfo[NotificationConstants.UserInfoKey.receiverIdentifier] = newValue
        }
    }

    override var roomID: String? {
        get {
            userInfo[NotificationConstants.UserInfoKey.roomIdentifier] as? String
        }
        set {
            userInfo[NotificationConstants.UserInfoKey.roomIdentifier] = newValue
        }
    }
    
    override var eventID: String? {
        get {
            userInfo[NotificationConstants.UserInfoKey.eventIdentifier] as? String
        }
        set {
            userInfo[NotificationConstants.UserInfoKey.eventIdentifier] = newValue
        }
    }

    func addMediaAttachment(using mediaProvider: MediaProviderProtocol?,
                            mediaSource: MediaSourceProxy) async -> UNMutableNotificationContent {
        guard let mediaProvider else {
            return self
        }
        switch await mediaProvider.loadFileFromSource(mediaSource) {
        case .success(let file):
            do {
                guard let url = file.url else {
                    MXLog.error("Couldn't add media attachment: URL is nil")
                    return self
                }
                let identifier = ProcessInfo.processInfo.globallyUniqueString
                let newURL = try FileManager.default.copyFileToTemporaryDirectory(file: url, with: "\(identifier).\(url.pathExtension)")
                let attachment = try UNNotificationAttachment(identifier: identifier,
                                                              url: newURL,
                                                              options: nil)
                attachments.append(attachment)
            } catch {
                MXLog.error("Couldn't add media attachment:: \(error)")
                return self
            }
        case .failure(let error):
            MXLog.error("Couldn't load the file for media attachment: \(error)")
        }

        return self
    }

    func addSenderIcon(using mediaProvider: MediaProviderProtocol?,
                       senderID: String,
                       senderName: String,
                       icon: NotificationIcon) async throws -> UNMutableNotificationContent {
        // We display the placeholder only if...
        var needsPlaceholder = false

        var fetchedImage: INImage?
        let image: INImage
        if let mediaSource = icon.mediaSource {
            switch await mediaProvider?.loadThumbnailForSource(source: mediaSource, size: .init(width: 100, height: 100)) {
            case .success(let data):
                fetchedImage = INImage(imageData: data)
            case .failure(let error):
                MXLog.error("Couldn't add sender icon: \(error)")
                // ...The provider failed to fetch
                needsPlaceholder = true
            case .none:
                break
            }
        } else {
            // ...There is no media
            needsPlaceholder = true
        }

        if let fetchedImage {
            image = fetchedImage
        } else if needsPlaceholder,
                  let data = await getPlaceholderAvatarImageData(name: icon.groupInfo?.name ?? senderName,
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
            let meHandle = INPersonHandle(value: receiverID, type: .unknown)
            let me = INPerson(personHandle: meHandle, nameComponents: nil, displayName: nil, image: nil, contactIdentifier: nil, customIdentifier: nil, isMe: true)
            speakableGroupName = INSpeakableString(spokenPhrase: groupInfo.name)
            recipients = [sender, me]
        }

        let intent = INSendMessageIntent(recipients: recipients,
                                         outgoingMessageType: .outgoingMessageText,
                                         content: nil,
                                         speakableGroupName: speakableGroupName,
                                         conversationIdentifier: roomID,
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
        try await interaction.donate()
        // Update notification content before displaying the
        // communication notification.
        let updatedContent = try updating(from: intent)

        // swiftlint:disable:next force_cast
        return updatedContent.mutableCopy() as! UNMutableNotificationContent
    }

    @MainActor
    private func getPlaceholderAvatarImageData(name: String, id: String) async -> Data? {
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

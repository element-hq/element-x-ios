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
import Intents
import UserNotifications

extension UNMutableNotificationContent {
    func addMediaAttachment(using mediaProvider: MediaProviderProtocol?,
                            mediaSource: MediaSourceProxy) async throws -> UNMutableNotificationContent {
        guard let mediaProvider else {
            return self
        }

        switch await mediaProvider.loadFileFromSource(mediaSource, fileExtension: "") {
        case .success(let url):
            let attachment = try UNNotificationAttachment(identifier: ProcessInfo.processInfo.globallyUniqueString,
                                                          url: url,
                                                          options: nil)
            attachments.append(attachment)
        case .failure(let error):
            MXLog.debug("Couldn't add media attachment: \(error)")
        }
        
        return self
    }
    
    func addSenderIcon(using mediaProvider: MediaProviderProtocol?,
                       senderId: String,
                       senderName: String,
                       mediaSource: MediaSourceProxy?,
                       roomId: String) async throws -> UNMutableNotificationContent {
        guard let mediaProvider, let mediaSource else {
            return self
        }

        switch await mediaProvider.loadFileFromSource(mediaSource, fileExtension: "jpg") {
        case .success(let url):
            // Initialize only the sender for a one-to-one message intent.
            let handle = INPersonHandle(value: senderId, type: .unknown)
            let sender = INPerson(personHandle: handle,
                                  nameComponents: nil,
                                  displayName: senderName,
                                  image: INImage(imageData: try Data(contentsOf: url)),
                                  contactIdentifier: nil,
                                  customIdentifier: nil)

            // Because this communication is incoming, you can infer that the current user is
            // a recipient. Don't include the current user when initializing the intent.
            let intent = INSendMessageIntent(recipients: nil,
                                             outgoingMessageType: .outgoingMessageText,
                                             content: nil,
                                             speakableGroupName: nil,
                                             conversationIdentifier: roomId,
                                             serviceName: nil,
                                             sender: sender,
                                             attachments: nil)

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

            return updatedContent.mutableCopy() as! UNMutableNotificationContent
        case .failure(let error):
            MXLog.debug("Couldn't add sender icon: \(error)")
            return self
        }
    }
}

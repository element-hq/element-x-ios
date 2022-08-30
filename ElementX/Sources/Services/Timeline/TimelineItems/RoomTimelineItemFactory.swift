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

import MatrixRustSDK
import UIKit

struct RoomTimelineItemFactory: RoomTimelineItemFactoryProtocol {
    private let mediaProvider: MediaProviderProtocol
    private let roomProxy: RoomProxyProtocol
    private let attributedStringBuilder: AttributedStringBuilderProtocol
    
    /// The Matrix ID of the current user.
    private let userID: String
    
    init(userID: String,
         mediaProvider: MediaProviderProtocol,
         roomProxy: RoomProxyProtocol,
         attributedStringBuilder: AttributedStringBuilderProtocol) {
        self.userID = userID
        self.mediaProvider = mediaProvider
        self.roomProxy = roomProxy
        self.attributedStringBuilder = attributedStringBuilder
    }
    
    func buildTimelineItemFor(eventItem: EventTimelineItem, showSenderDetails: Bool) async -> RoomTimelineItemProtocol {
        guard let messageContent = eventItem.content.asMessage() else { fatalError("Must be a message for now.") }
        let displayName = roomProxy.displayNameForUserId(eventItem.sender)
        let avatarURL = roomProxy.avatarURLStringForUserId(eventItem.sender)
        let avatarImage = mediaProvider.imageFromURLString(avatarURL)
        let isOutgoing = eventItem.sender == userID
        
        if let textContent = messageContent.msgtype().asText() {
            let message = MessageTimelineItem(item: eventItem.item, content: textContent)
            return await buildTextTimelineItemFromMessage(message, isOutgoing, showSenderDetails, displayName, avatarImage)
        } else if let imageContent = messageContent.msgtype().asImage() {
            let message = MessageTimelineItem(item: eventItem.item, content: imageContent)
            return await buildImageTimelineItemFromMessage(message, isOutgoing, showSenderDetails, displayName, avatarImage)
        } else if let noticeContent = messageContent.msgtype().asNotice() {
            let message = MessageTimelineItem(item: eventItem.item, content: noticeContent)
            return await buildNoticeTimelineItemFromMessage(message, isOutgoing, showSenderDetails, displayName, avatarImage)
        } else if let emoteContent = messageContent.msgtype().asEmote() {
            let message = MessageTimelineItem(item: eventItem.item, content: emoteContent)
            return await buildEmoteTimelineItemFromMessage(message, isOutgoing, showSenderDetails, displayName, avatarImage)
        } else {
            return await buildFallbackTimelineItemFromMessage(eventItem, messageContent.msgtype(), isOutgoing, showSenderDetails, displayName, avatarImage)
        }
    }
    
    // MARK: - Private

    private func buildFallbackTimelineItemFromMessage(_ item: EventTimelineItem,
                                                      _ content: MessageType,
                                                      _ isOutgoing: Bool,
                                                      _ showSenderDetails: Bool,
                                                      _ displayName: String?,
                                                      _ avatarImage: UIImage?) async -> RoomTimelineItemProtocol {
        let attributedText = await attributedStringBuilder.fromPlain(content.body())
        let attributedComponents = attributedStringBuilder.blockquoteCoalescedComponentsFrom(attributedText)
        
        return TextRoomTimelineItem(id: item.id,
                                    text: content.body(),
                                    attributedComponents: attributedComponents,
                                    timestamp: item.originServerTs.formatted(date: .omitted, time: .shortened),
                                    shouldShowSenderDetails: showSenderDetails,
                                    isOutgoing: isOutgoing,
                                    senderId: item.sender,
                                    senderDisplayName: displayName,
                                    senderAvatar: avatarImage,
                                    properties: RoomTimelineItemProperties(isEdited: item.content.asMessage()?.isEdited() ?? false,
                                                                           reactions: [])); #warning("Get the reactions properly here.")
    }
    
    private func buildTextTimelineItemFromMessage(_ message: MessageTimelineItem<TextMessageContent>,
                                                  _ isOutgoing: Bool,
                                                  _ showSenderDetails: Bool,
                                                  _ displayName: String?,
                                                  _ avatarImage: UIImage?) async -> RoomTimelineItemProtocol {
        let attributedText = await (message.htmlBody != nil ? attributedStringBuilder.fromHTML(message.htmlBody) : attributedStringBuilder.fromPlain(message.body))
        let attributedComponents = attributedStringBuilder.blockquoteCoalescedComponentsFrom(attributedText)
        
        return TextRoomTimelineItem(id: message.id,
                                    text: message.body,
                                    attributedComponents: attributedComponents,
                                    timestamp: message.originServerTs.formatted(date: .omitted, time: .shortened),
                                    shouldShowSenderDetails: showSenderDetails,
                                    isOutgoing: isOutgoing,
                                    senderId: message.sender,
                                    senderDisplayName: displayName,
                                    senderAvatar: avatarImage,
                                    properties: RoomTimelineItemProperties(isEdited: message.isEdited,
                                                                           reactions: aggregateReactions(message.reactions)))
    }
    
    private func buildImageTimelineItemFromMessage(_ message: MessageTimelineItem<ImageMessageContent>,
                                                   _ isOutgoing: Bool,
                                                   _ showSenderDetails: Bool,
                                                   _ displayName: String?,
                                                   _ avatarImage: UIImage?) async -> RoomTimelineItemProtocol {
        var aspectRatio: CGFloat?
        if let width = message.width,
           let height = message.height {
            aspectRatio = width / height
        }
        
        return ImageRoomTimelineItem(id: message.id,
                                     text: message.body,
                                     timestamp: message.originServerTs.formatted(date: .omitted, time: .shortened),
                                     shouldShowSenderDetails: showSenderDetails,
                                     isOutgoing: isOutgoing,
                                     senderId: message.sender,
                                     senderDisplayName: displayName,
                                     senderAvatar: avatarImage,
                                     source: message.source,
                                     image: mediaProvider.imageFromSource(message.source),
                                     width: message.width,
                                     height: message.height,
                                     aspectRatio: aspectRatio,
                                     blurhash: message.blurhash,
                                     properties: RoomTimelineItemProperties(isEdited: message.isEdited,
                                                                            reactions: aggregateReactions(message.reactions)))
    }
    
    private func buildNoticeTimelineItemFromMessage(_ message: MessageTimelineItem<NoticeMessageContent>,
                                                    _ isOutgoing: Bool,
                                                    _ showSenderDetails: Bool,
                                                    _ displayName: String?,
                                                    _ avatarImage: UIImage?) async -> RoomTimelineItemProtocol {
        let attributedText = await (message.htmlBody != nil ? attributedStringBuilder.fromHTML(message.htmlBody) : attributedStringBuilder.fromPlain(message.body))
        let attributedComponents = attributedStringBuilder.blockquoteCoalescedComponentsFrom(attributedText)
        
        return NoticeRoomTimelineItem(id: message.id,
                                      text: message.body,
                                      attributedComponents: attributedComponents,
                                      timestamp: message.originServerTs.formatted(date: .omitted, time: .shortened),
                                      shouldShowSenderDetails: showSenderDetails,
                                      isOutgoing: isOutgoing,
                                      senderId: message.sender,
                                      senderDisplayName: displayName,
                                      senderAvatar: avatarImage,
                                      properties: RoomTimelineItemProperties(isEdited: message.isEdited,
                                                                             reactions: aggregateReactions(message.reactions)))
    }
    
    private func buildEmoteTimelineItemFromMessage(_ message: MessageTimelineItem<EmoteMessageContent>,
                                                   _ isOutgoing: Bool,
                                                   _ showSenderDetails: Bool,
                                                   _ displayName: String?,
                                                   _ avatarImage: UIImage?) async -> RoomTimelineItemProtocol {
        let attributedText = await (message.htmlBody != nil ? attributedStringBuilder.fromHTML(message.htmlBody) : attributedStringBuilder.fromPlain(message.body))
        let attributedComponents = attributedStringBuilder.blockquoteCoalescedComponentsFrom(attributedText)
        
        return EmoteRoomTimelineItem(id: message.id,
                                     text: message.body,
                                     attributedComponents: attributedComponents,
                                     timestamp: message.originServerTs.formatted(date: .omitted, time: .shortened),
                                     shouldShowSenderDetails: showSenderDetails,
                                     isOutgoing: isOutgoing,
                                     senderId: message.sender,
                                     senderDisplayName: displayName,
                                     senderAvatar: avatarImage,
                                     properties: RoomTimelineItemProperties(isEdited: message.isEdited,
                                                                            reactions: aggregateReactions(message.reactions)))
    }
    
    private func aggregateReactions(_ reactions: [Reaction]) -> [AggregatedReaction] {
        return reactions.map { reaction in
            let isHighlighted = false // reaction.details.contains(where: { $0.sender == userID })
            return AggregatedReaction(key: reaction.key, count: Int(reaction.count), isHighlighted: isHighlighted)
        }
    }
}

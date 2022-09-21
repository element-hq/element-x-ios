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
    
    func buildTimelineItemFor(eventItem: EventTimelineItem,
                              showSenderDetails: Bool,
                              inGroupState: TimelineItemInGroupState) async -> RoomTimelineItemProtocol {
        guard let messageContent = eventItem.content.asMessage() else { fatalError("Must be a message for now.") }
        let displayName = roomProxy.displayNameForUserId(eventItem.sender)
        let avatarURL = roomProxy.avatarURLStringForUserId(eventItem.sender)
        let avatarImage = mediaProvider.imageFromURLString(avatarURL, size: MediaProviderDefaultAvatarSize)
        let isOutgoing = eventItem.isOwn
        
        switch messageContent.msgtype() {
        case .text(content: let content):
            let message = MessageTimelineItem(item: eventItem.item, content: content)
            return await buildTextTimelineItemFromMessage(message, isOutgoing, showSenderDetails, inGroupState, displayName, avatarImage)
        case .image(content: let content):
            let message = MessageTimelineItem(item: eventItem.item, content: content)
            return await buildImageTimelineItemFromMessage(message, isOutgoing, showSenderDetails, inGroupState, displayName, avatarImage)
        case .notice(content: let content):
            let message = MessageTimelineItem(item: eventItem.item, content: content)
            return await buildNoticeTimelineItemFromMessage(message, isOutgoing, showSenderDetails, inGroupState, displayName, avatarImage)
        case .emote(content: let content):
            let message = MessageTimelineItem(item: eventItem.item, content: content)
            return await buildEmoteTimelineItemFromMessage(message, isOutgoing, showSenderDetails, inGroupState, displayName, avatarImage)
        case .none:
            return await buildFallbackTimelineItem(eventItem, isOutgoing, showSenderDetails, inGroupState, displayName, avatarImage)
        }
    }
    
    // MARK: - Private

    // swiftformat:disable function_parameter_count
    // swiftlint:disable function_parameter_count
    private func buildFallbackTimelineItem(_ item: EventTimelineItem,
                                           _ isOutgoing: Bool,
                                           _ showSenderDetails: Bool,
                                           _ inGroupState: TimelineItemInGroupState,
                                           _ displayName: String?,
                                           _ avatarImage: UIImage?) async -> RoomTimelineItemProtocol {
        let attributedText = await attributedStringBuilder.fromPlain(item.body)
        let attributedComponents = attributedStringBuilder.blockquoteCoalescedComponentsFrom(attributedText)
        
        return TextRoomTimelineItem(id: item.id,
                                    text: item.body ?? "",
                                    attributedComponents: attributedComponents,
                                    timestamp: item.originServerTs.formatted(date: .omitted, time: .shortened),
                                    shouldShowSenderDetails: showSenderDetails,
                                    inGroupState: inGroupState,
                                    isOutgoing: isOutgoing,
                                    senderId: item.sender,
                                    senderDisplayName: displayName,
                                    senderAvatar: avatarImage,
                                    properties: RoomTimelineItemProperties(isEdited: item.content.asMessage()?.isEdited() ?? false,
                                                                           reactions: aggregateReactions(item.reactions)))
    }
    
    private func buildTextTimelineItemFromMessage(_ message: MessageTimelineItem<TextMessageContent>,
                                                  _ isOutgoing: Bool,
                                                  _ showSenderDetails: Bool,
                                                  _ inGroupState: TimelineItemInGroupState,
                                                  _ displayName: String?,
                                                  _ avatarImage: UIImage?) async -> RoomTimelineItemProtocol {
        let attributedText = await (message.htmlBody != nil ? attributedStringBuilder.fromHTML(message.htmlBody) : attributedStringBuilder.fromPlain(message.body))
        let attributedComponents = attributedStringBuilder.blockquoteCoalescedComponentsFrom(attributedText)
        
        return TextRoomTimelineItem(id: message.id,
                                    text: message.body,
                                    attributedComponents: attributedComponents,
                                    timestamp: message.originServerTs.formatted(date: .omitted, time: .shortened),
                                    shouldShowSenderDetails: showSenderDetails,
                                    inGroupState: inGroupState,
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
                                                   _ inGroupState: TimelineItemInGroupState,
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
                                     inGroupState: inGroupState,
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
                                                    _ inGroupState: TimelineItemInGroupState,
                                                    _ displayName: String?,
                                                    _ avatarImage: UIImage?) async -> RoomTimelineItemProtocol {
        let attributedText = await (message.htmlBody != nil ? attributedStringBuilder.fromHTML(message.htmlBody) : attributedStringBuilder.fromPlain(message.body))
        let attributedComponents = attributedStringBuilder.blockquoteCoalescedComponentsFrom(attributedText)
        
        return NoticeRoomTimelineItem(id: message.id,
                                      text: message.body,
                                      attributedComponents: attributedComponents,
                                      timestamp: message.originServerTs.formatted(date: .omitted, time: .shortened),
                                      shouldShowSenderDetails: showSenderDetails,
                                      inGroupState: inGroupState,
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
                                                   _ inGroupState: TimelineItemInGroupState,
                                                   _ displayName: String?,
                                                   _ avatarImage: UIImage?) async -> RoomTimelineItemProtocol {
        let attributedText = await (message.htmlBody != nil ? attributedStringBuilder.fromHTML(message.htmlBody) : attributedStringBuilder.fromPlain(message.body))
        let attributedComponents = attributedStringBuilder.blockquoteCoalescedComponentsFrom(attributedText)
        
        return EmoteRoomTimelineItem(id: message.id,
                                     text: message.body,
                                     attributedComponents: attributedComponents,
                                     timestamp: message.originServerTs.formatted(date: .omitted, time: .shortened),
                                     shouldShowSenderDetails: showSenderDetails,
                                     inGroupState: inGroupState,
                                     isOutgoing: isOutgoing,
                                     senderId: message.sender,
                                     senderDisplayName: displayName,
                                     senderAvatar: avatarImage,
                                     properties: RoomTimelineItemProperties(isEdited: message.isEdited,
                                                                            reactions: aggregateReactions(message.reactions)))
    }
    
    // swiftlint:enable function_parameter_count
    // swiftformat:enable function_parameter_count
    
    private func aggregateReactions(_ reactions: [Reaction]) -> [AggregatedReaction] {
        reactions.map { reaction in
            let isHighlighted = false // reaction.details.contains(where: { $0.sender == userID })
            return AggregatedReaction(key: reaction.key, count: Int(reaction.count), isHighlighted: isHighlighted)
        }
    }
}

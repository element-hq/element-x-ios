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
    private let attributedStringBuilder: AttributedStringBuilderProtocol
    
    /// The Matrix ID of the current user.
    private let userID: String
    
    init(userID: String,
         mediaProvider: MediaProviderProtocol,
         attributedStringBuilder: AttributedStringBuilderProtocol) {
        self.userID = userID
        self.mediaProvider = mediaProvider
        self.attributedStringBuilder = attributedStringBuilder
    }
    
    // swiftlint:disable:next cyclomatic_complexity
    func buildTimelineItemFor(eventItemProxy: EventTimelineItemProxy,
                              groupState: TimelineItemGroupState) -> RoomTimelineItemProtocol {
        var avatarImage: UIImage?
        if let senderAvatarURL = eventItemProxy.senderAvatarURL {
            avatarImage = mediaProvider.imageFromURL(senderAvatarURL, avatarSize: .user(on: .timeline))
        }
        
        let isOutgoing = eventItemProxy.isOwn
        
        switch eventItemProxy.content.kind() {
        case .unableToDecrypt(let encryptedMessage):
            return buildEncryptedTimelineItem(eventItemProxy, encryptedMessage, isOutgoing, groupState, avatarImage)
        case .redactedMessage:
            return buildRedactedTimelineItem(eventItemProxy, isOutgoing, groupState, avatarImage)
        case .sticker(let body, let imageInfo, let url):
            return buildStickerTimelineItem(eventItemProxy, body, imageInfo, url, isOutgoing, groupState, avatarImage)
        case .failedToParseMessageLike(let eventType, let error):
            return buildUnsupportedTimelineItem(eventItemProxy, eventType, error, isOutgoing, groupState, avatarImage)
        case .failedToParseState(let eventType, _, let error):
            return buildUnsupportedTimelineItem(eventItemProxy, eventType, error, isOutgoing, groupState, avatarImage)
        case .message:
            guard let messageContent = eventItemProxy.content.asMessage() else { fatalError("Invalid message timeline item: \(eventItemProxy)") }
            
            switch messageContent.msgtype() {
            case .text(content: let content):
                let message = MessageTimelineItem(item: eventItemProxy.item, content: content)
                return buildTextTimelineItemFromMessage(eventItemProxy, message, isOutgoing, groupState, avatarImage)
            case .image(content: let content):
                let message = MessageTimelineItem(item: eventItemProxy.item, content: content)
                return buildImageTimelineItemFromMessage(eventItemProxy, message, isOutgoing, groupState, avatarImage)
            case .video(let content):
                let message = MessageTimelineItem(item: eventItemProxy.item, content: content)
                return buildVideoTimelineItemFromMessage(eventItemProxy, message, isOutgoing, groupState, avatarImage)
            case .file(let content):
                let message = MessageTimelineItem(item: eventItemProxy.item, content: content)
                return buildFileTimelineItemFromMessage(eventItemProxy, message, isOutgoing, groupState, avatarImage)
            case .notice(content: let content):
                let message = MessageTimelineItem(item: eventItemProxy.item, content: content)
                return buildNoticeTimelineItemFromMessage(eventItemProxy, message, isOutgoing, groupState, avatarImage)
            case .emote(content: let content):
                let message = MessageTimelineItem(item: eventItemProxy.item, content: content)
                return buildEmoteTimelineItemFromMessage(eventItemProxy, message, isOutgoing, groupState, avatarImage)
            case .none:
                return buildFallbackTimelineItem(eventItemProxy, isOutgoing, groupState, avatarImage)
            }
        }
    }
    
    // MARK: - Private
    
    // swiftlint:disable:next function_parameter_count
    private func buildUnsupportedTimelineItem(_ eventItemProxy: EventTimelineItemProxy,
                                              _ eventType: String,
                                              _ error: String,
                                              _ isOutgoing: Bool,
                                              _ groupState: TimelineItemGroupState,
                                              _ avatarImage: UIImage?) -> RoomTimelineItemProtocol {
        UnsupportedRoomTimelineItem(id: eventItemProxy.id,
                                    text: ElementL10n.roomTimelineItemUnsupported,
                                    eventType: eventType,
                                    error: error,
                                    timestamp: eventItemProxy.timestamp.formatted(date: .omitted, time: .shortened),
                                    groupState: groupState,
                                    isOutgoing: isOutgoing,
                                    isEditable: eventItemProxy.isEditable,
                                    senderId: eventItemProxy.sender,
                                    senderDisplayName: eventItemProxy.senderDisplayName,
                                    senderAvatarURL: eventItemProxy.senderAvatarURL,
                                    senderAvatar: avatarImage,
                                    properties: RoomTimelineItemProperties())
    }
    
    // swiftlint:disable:next function_parameter_count
    private func buildStickerTimelineItem(_ eventItemProxy: EventTimelineItemProxy,
                                          _ body: String,
                                          _ imageInfo: ImageInfo,
                                          _ imageURLString: String,
                                          _ isOutgoing: Bool,
                                          _ groupState: TimelineItemGroupState,
                                          _ avatarImage: UIImage?) -> RoomTimelineItemProtocol {
        var aspectRatio: CGFloat?
        let width = imageInfo.width.map(CGFloat.init)
        let height = imageInfo.height.map(CGFloat.init)
        if let width, let height {
            aspectRatio = width / height
        }
        
        var image: UIImage?
        if let url = URL(string: imageURLString) {
            image = mediaProvider.imageFromURL(url)
        }

        return StickerRoomTimelineItem(id: eventItemProxy.id,
                                       text: body,
                                       timestamp: eventItemProxy.timestamp.formatted(date: .omitted, time: .shortened),
                                       groupState: groupState,
                                       isOutgoing: isOutgoing,
                                       isEditable: eventItemProxy.isEditable,
                                       senderId: eventItemProxy.sender,
                                       senderDisplayName: eventItemProxy.senderDisplayName,
                                       senderAvatarURL: eventItemProxy.senderAvatarURL,
                                       senderAvatar: avatarImage,
                                       imageURL: URL(string: imageURLString),
                                       image: image,
                                       width: width,
                                       height: height,
                                       aspectRatio: aspectRatio,
                                       blurhash: imageInfo.blurhash,
                                       properties: RoomTimelineItemProperties(reactions: aggregateReactions(eventItemProxy.reactions),
                                                                              deliveryStatus: eventItemProxy.deliveryStatus))
    }
    
    private func buildEncryptedTimelineItem(_ eventItemProxy: EventTimelineItemProxy,
                                            _ encryptedMessage: EncryptedMessage,
                                            _ isOutgoing: Bool,
                                            _ groupState: TimelineItemGroupState,
                                            _ avatarImage: UIImage?) -> RoomTimelineItemProtocol {
        var encryptionType = EncryptedRoomTimelineItem.EncryptionType.unknown
        switch encryptedMessage {
        case .megolmV1AesSha2(let sessionId):
            encryptionType = .megolmV1AesSha2(sessionId: sessionId)
        case .olmV1Curve25519AesSha2(let senderKey):
            encryptionType = .olmV1Curve25519AesSha2(senderKey: senderKey)
        default:
            break
        }
        
        return EncryptedRoomTimelineItem(id: eventItemProxy.id,
                                         text: ElementL10n.encryptionInformationDecryptionError,
                                         encryptionType: encryptionType,
                                         timestamp: eventItemProxy.timestamp.formatted(date: .omitted, time: .shortened),
                                         groupState: groupState,
                                         isOutgoing: isOutgoing,
                                         isEditable: eventItemProxy.isEditable,
                                         senderId: eventItemProxy.sender,
                                         senderDisplayName: eventItemProxy.senderDisplayName,
                                         senderAvatarURL: eventItemProxy.senderAvatarURL,
                                         senderAvatar: avatarImage,
                                         properties: RoomTimelineItemProperties())
    }
    
    private func buildRedactedTimelineItem(_ eventItemProxy: EventTimelineItemProxy,
                                           _ isOutgoing: Bool,
                                           _ groupState: TimelineItemGroupState,
                                           _ avatarImage: UIImage?) -> RoomTimelineItemProtocol {
        RedactedRoomTimelineItem(id: eventItemProxy.id,
                                 text: ElementL10n.eventRedacted,
                                 timestamp: eventItemProxy.timestamp.formatted(date: .omitted, time: .shortened),
                                 groupState: groupState,
                                 isOutgoing: isOutgoing,
                                 isEditable: eventItemProxy.isEditable,
                                 senderId: eventItemProxy.sender,
                                 senderDisplayName: eventItemProxy.senderDisplayName,
                                 senderAvatarURL: eventItemProxy.senderAvatarURL,
                                 senderAvatar: avatarImage,
                                 properties: RoomTimelineItemProperties())
    }

    private func buildFallbackTimelineItem(_ eventItemProxy: EventTimelineItemProxy,
                                           _ isOutgoing: Bool,
                                           _ groupState: TimelineItemGroupState,
                                           _ avatarImage: UIImage?) -> RoomTimelineItemProtocol {
        let attributedText = attributedStringBuilder.fromPlain(eventItemProxy.body)
        let attributedComponents = attributedStringBuilder.blockquoteCoalescedComponentsFrom(attributedText)
        
        return TextRoomTimelineItem(id: eventItemProxy.id,
                                    text: eventItemProxy.body ?? "",
                                    attributedComponents: attributedComponents,
                                    timestamp: eventItemProxy.timestamp.formatted(date: .omitted, time: .shortened),
                                    groupState: groupState,
                                    isOutgoing: isOutgoing,
                                    isEditable: eventItemProxy.isEditable,
                                    senderId: eventItemProxy.sender,
                                    senderDisplayName: eventItemProxy.senderDisplayName,
                                    senderAvatarURL: eventItemProxy.senderAvatarURL,
                                    senderAvatar: avatarImage,
                                    properties: RoomTimelineItemProperties(isEdited: eventItemProxy.content.asMessage()?.isEdited() ?? false,
                                                                           reactions: aggregateReactions(eventItemProxy.reactions)))
    }
    
    private func buildTextTimelineItemFromMessage(_ eventItemProxy: EventTimelineItemProxy,
                                                  _ message: MessageTimelineItem<TextMessageContent>,
                                                  _ isOutgoing: Bool,
                                                  _ groupState: TimelineItemGroupState,
                                                  _ avatarImage: UIImage?) -> RoomTimelineItemProtocol {
        let attributedText = (message.htmlBody != nil ? attributedStringBuilder.fromHTML(message.htmlBody) : attributedStringBuilder.fromPlain(message.body))
        let attributedComponents = attributedStringBuilder.blockquoteCoalescedComponentsFrom(attributedText)
        
        return TextRoomTimelineItem(id: message.id,
                                    text: message.body,
                                    attributedComponents: attributedComponents,
                                    timestamp: message.timestamp.formatted(date: .omitted, time: .shortened),
                                    groupState: groupState,
                                    isOutgoing: isOutgoing,
                                    isEditable: eventItemProxy.isEditable,
                                    senderId: message.sender,
                                    senderDisplayName: eventItemProxy.senderDisplayName,
                                    senderAvatarURL: eventItemProxy.senderAvatarURL,
                                    senderAvatar: avatarImage,
                                    properties: RoomTimelineItemProperties(isEdited: message.isEdited,
                                                                           reactions: aggregateReactions(eventItemProxy.reactions),
                                                                           deliveryStatus: eventItemProxy.deliveryStatus))
    }
    
    private func buildImageTimelineItemFromMessage(_ eventItemProxy: EventTimelineItemProxy,
                                                   _ message: MessageTimelineItem<ImageMessageContent>,
                                                   _ isOutgoing: Bool,
                                                   _ groupState: TimelineItemGroupState,
                                                   _ avatarImage: UIImage?) -> RoomTimelineItemProtocol {
        var aspectRatio: CGFloat?
        if let width = message.width,
           let height = message.height {
            aspectRatio = width / height
        }
        
        return ImageRoomTimelineItem(id: message.id,
                                     text: message.body,
                                     timestamp: message.timestamp.formatted(date: .omitted, time: .shortened),
                                     groupState: groupState,
                                     isOutgoing: isOutgoing,
                                     isEditable: eventItemProxy.isEditable,
                                     senderId: message.sender,
                                     senderDisplayName: eventItemProxy.senderDisplayName,
                                     senderAvatarURL: eventItemProxy.senderAvatarURL,
                                     senderAvatar: avatarImage,
                                     source: message.source,
                                     image: mediaProvider.imageFromSource(message.source),
                                     width: message.width,
                                     height: message.height,
                                     aspectRatio: aspectRatio,
                                     blurhash: message.blurhash,
                                     properties: RoomTimelineItemProperties(isEdited: message.isEdited,
                                                                            reactions: aggregateReactions(eventItemProxy.reactions),
                                                                            deliveryStatus: eventItemProxy.deliveryStatus))
    }
    
    private func buildVideoTimelineItemFromMessage(_ eventItemProxy: EventTimelineItemProxy,
                                                   _ message: MessageTimelineItem<VideoMessageContent>,
                                                   _ isOutgoing: Bool,
                                                   _ groupState: TimelineItemGroupState,
                                                   _ avatarImage: UIImage?) -> RoomTimelineItemProtocol {
        var aspectRatio: CGFloat?
        if let width = message.width,
           let height = message.height {
            aspectRatio = width / height
        }
        
        return VideoRoomTimelineItem(id: message.id,
                                     text: message.body,
                                     timestamp: message.timestamp.formatted(date: .omitted, time: .shortened),
                                     groupState: groupState,
                                     isOutgoing: isOutgoing,
                                     isEditable: eventItemProxy.isEditable,
                                     senderId: message.sender,
                                     senderDisplayName: eventItemProxy.senderDisplayName,
                                     senderAvatarURL: eventItemProxy.senderAvatarURL,
                                     senderAvatar: avatarImage,
                                     duration: message.duration,
                                     source: message.source,
                                     thumbnailSource: message.thumbnailSource,
                                     image: mediaProvider.imageFromSource(message.thumbnailSource),
                                     width: message.width,
                                     height: message.height,
                                     aspectRatio: aspectRatio,
                                     blurhash: message.blurhash,
                                     properties: RoomTimelineItemProperties(isEdited: message.isEdited,
                                                                            reactions: aggregateReactions(eventItemProxy.reactions),
                                                                            deliveryStatus: eventItemProxy.deliveryStatus))
    }

    private func buildFileTimelineItemFromMessage(_ eventItemProxy: EventTimelineItemProxy,
                                                  _ message: MessageTimelineItem<FileMessageContent>,
                                                  _ isOutgoing: Bool,
                                                  _ groupState: TimelineItemGroupState,
                                                  _ avatarImage: UIImage?) -> RoomTimelineItemProtocol {
        FileRoomTimelineItem(id: message.id,
                             text: message.body,
                             timestamp: message.timestamp.formatted(date: .omitted, time: .shortened),
                             groupState: groupState,
                             isOutgoing: isOutgoing,
                             isEditable: eventItemProxy.isEditable,
                             senderId: message.sender,
                             senderDisplayName: eventItemProxy.senderDisplayName,
                             senderAvatarURL: eventItemProxy.senderAvatarURL,
                             senderAvatar: avatarImage,
                             source: message.source,
                             thumbnailSource: message.thumbnailSource,
                             properties: RoomTimelineItemProperties(isEdited: message.isEdited,
                                                                    reactions: aggregateReactions(eventItemProxy.reactions),
                                                                    deliveryStatus: eventItemProxy.deliveryStatus))
    }
    
    private func buildNoticeTimelineItemFromMessage(_ eventItemProxy: EventTimelineItemProxy,
                                                    _ message: MessageTimelineItem<NoticeMessageContent>,
                                                    _ isOutgoing: Bool,
                                                    _ groupState: TimelineItemGroupState,
                                                    _ avatarImage: UIImage?) -> RoomTimelineItemProtocol {
        let attributedText = (message.htmlBody != nil ? attributedStringBuilder.fromHTML(message.htmlBody) : attributedStringBuilder.fromPlain(message.body))
        let attributedComponents = attributedStringBuilder.blockquoteCoalescedComponentsFrom(attributedText)
        
        return NoticeRoomTimelineItem(id: message.id,
                                      text: message.body,
                                      attributedComponents: attributedComponents,
                                      timestamp: message.timestamp.formatted(date: .omitted, time: .shortened),
                                      groupState: groupState,
                                      isOutgoing: isOutgoing,
                                      isEditable: eventItemProxy.isEditable,
                                      senderId: message.sender,
                                      senderDisplayName: eventItemProxy.senderDisplayName,
                                      senderAvatarURL: eventItemProxy.senderAvatarURL,
                                      senderAvatar: avatarImage,
                                      properties: RoomTimelineItemProperties(isEdited: message.isEdited,
                                                                             reactions: aggregateReactions(eventItemProxy.reactions),
                                                                             deliveryStatus: eventItemProxy.deliveryStatus))
    }
    
    private func buildEmoteTimelineItemFromMessage(_ eventItemProxy: EventTimelineItemProxy,
                                                   _ message: MessageTimelineItem<EmoteMessageContent>,
                                                   _ isOutgoing: Bool,
                                                   _ groupState: TimelineItemGroupState,
                                                   _ avatarImage: UIImage?) -> RoomTimelineItemProtocol {
        let name = eventItemProxy.senderDisplayName ?? eventItemProxy.sender

        var attributedText: AttributedString?
        if let htmlBody = message.htmlBody {
            attributedText = attributedStringBuilder.fromHTML("* \(name) \(htmlBody)")
        } else {
            attributedText = attributedStringBuilder.fromPlain("* \(name) \(message.body)")
        }
        
        let attributedComponents = attributedStringBuilder.blockquoteCoalescedComponentsFrom(attributedText)
        
        return EmoteRoomTimelineItem(id: message.id,
                                     text: message.body,
                                     attributedComponents: attributedComponents,
                                     timestamp: message.timestamp.formatted(date: .omitted, time: .shortened),
                                     groupState: groupState,
                                     isOutgoing: isOutgoing,
                                     isEditable: eventItemProxy.isEditable,
                                     senderId: message.sender,
                                     senderDisplayName: eventItemProxy.senderDisplayName,
                                     senderAvatarURL: eventItemProxy.senderAvatarURL,
                                     senderAvatar: avatarImage,
                                     properties: RoomTimelineItemProperties(isEdited: message.isEdited,
                                                                            reactions: aggregateReactions(eventItemProxy.reactions),
                                                                            deliveryStatus: eventItemProxy.deliveryStatus))
    }
    
    private func aggregateReactions(_ reactions: [Reaction]) -> [AggregatedReaction] {
        reactions.map { reaction in
            let isHighlighted = false // reaction.details.contains(where: { $0.sender == userID })
            return AggregatedReaction(key: reaction.key, count: Int(reaction.count), isHighlighted: isHighlighted)
        }
    }
}

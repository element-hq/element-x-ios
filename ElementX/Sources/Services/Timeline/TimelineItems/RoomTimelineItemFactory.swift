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
    private let roomStateTimelineItemFactory: RoomStateTimelineItemFactory
    
    /// The Matrix ID of the current user.
    private let userID: String
    
    init(userID: String,
         mediaProvider: MediaProviderProtocol,
         attributedStringBuilder: AttributedStringBuilderProtocol,
         roomStateTimelineItemFactory: RoomStateTimelineItemFactory) {
        self.userID = userID
        self.mediaProvider = mediaProvider
        self.attributedStringBuilder = attributedStringBuilder
        self.roomStateTimelineItemFactory = roomStateTimelineItemFactory
    }
    
    // swiftlint:disable:next cyclomatic_complexity
    func buildTimelineItemFor(eventItemProxy: EventTimelineItemProxy,
                              groupState: TimelineItemGroupState) -> RoomTimelineItemProtocol? {
        var sender = eventItemProxy.sender
        if let senderAvatarURL = eventItemProxy.sender.avatarURL,
           let image = mediaProvider.imageFromURL(senderAvatarURL, avatarSize: .user(on: .timeline)) {
            sender.avatar = image
        }
        
        let isOutgoing = eventItemProxy.isOwn
        
        switch eventItemProxy.content.kind() {
        case .unableToDecrypt(let encryptedMessage):
            return buildEncryptedTimelineItem(eventItemProxy, encryptedMessage, sender, isOutgoing, groupState)
        case .redactedMessage:
            return buildRedactedTimelineItem(eventItemProxy, sender, isOutgoing, groupState)
        case .sticker(let body, let imageInfo, let url):
            return buildStickerTimelineItem(eventItemProxy, body, imageInfo, url, sender, isOutgoing, groupState)
        case .failedToParseMessageLike(let eventType, let error):
            return buildUnsupportedTimelineItem(eventItemProxy, eventType, error, sender, isOutgoing, groupState)
        case .failedToParseState(let eventType, _, let error):
            return buildUnsupportedTimelineItem(eventItemProxy, eventType, error, sender, isOutgoing, groupState)
        case .message:
            guard let messageContent = eventItemProxy.content.asMessage() else { fatalError("Invalid message timeline item: \(eventItemProxy)") }
            
            switch messageContent.msgtype() {
            case .text(content: let content):
                let message = MessageTimelineItem(item: eventItemProxy.item, content: content)
                return buildTextTimelineItemFromMessage(eventItemProxy, message, sender, isOutgoing, groupState)
            case .image(content: let content):
                let message = MessageTimelineItem(item: eventItemProxy.item, content: content)
                return buildImageTimelineItemFromMessage(eventItemProxy, message, sender, isOutgoing, groupState)
            case .video(let content):
                let message = MessageTimelineItem(item: eventItemProxy.item, content: content)
                return buildVideoTimelineItemFromMessage(eventItemProxy, message, sender, isOutgoing, groupState)
            case .file(let content):
                let message = MessageTimelineItem(item: eventItemProxy.item, content: content)
                return buildFileTimelineItemFromMessage(eventItemProxy, message, sender, isOutgoing, groupState)
            case .notice(content: let content):
                let message = MessageTimelineItem(item: eventItemProxy.item, content: content)
                return buildNoticeTimelineItemFromMessage(eventItemProxy, message, sender, isOutgoing, groupState)
            case .emote(content: let content):
                let message = MessageTimelineItem(item: eventItemProxy.item, content: content)
                return buildEmoteTimelineItemFromMessage(eventItemProxy, message, sender, isOutgoing, groupState)
            case .none:
                return buildFallbackTimelineItem(eventItemProxy, sender, isOutgoing, groupState)
            }
        case .state(let stateKey, let content):
            return buildStateTimelineItemFor(eventItemProxy: eventItemProxy, content: content, stateKey: stateKey, sender: sender, isOutgoing: isOutgoing)
        case .roomMembership(userId: let userID, change: let change):
            return buildStateMembershipChangeTimelineItemFor(eventItemProxy: eventItemProxy, member: userID, change: change, sender: sender, isOutgoing: isOutgoing)
        }
    }
    
    // MARK: - Message Events
    
    // swiftlint:disable:next function_parameter_count
    private func buildUnsupportedTimelineItem(_ eventItemProxy: EventTimelineItemProxy,
                                              _ eventType: String,
                                              _ error: String,
                                              _ sender: TimelineItemSender,
                                              _ isOutgoing: Bool,
                                              _ groupState: TimelineItemGroupState) -> RoomTimelineItemProtocol {
        UnsupportedRoomTimelineItem(id: eventItemProxy.id,
                                    text: ElementL10n.roomTimelineItemUnsupported,
                                    eventType: eventType,
                                    error: error,
                                    timestamp: eventItemProxy.timestamp.formatted(date: .omitted, time: .shortened),
                                    groupState: groupState,
                                    isOutgoing: isOutgoing,
                                    isEditable: eventItemProxy.isEditable,
                                    sender: sender,
                                    properties: RoomTimelineItemProperties())
    }
    
    // swiftlint:disable:next function_parameter_count
    private func buildStickerTimelineItem(_ eventItemProxy: EventTimelineItemProxy,
                                          _ body: String,
                                          _ imageInfo: ImageInfo,
                                          _ imageURLString: String,
                                          _ sender: TimelineItemSender,
                                          _ isOutgoing: Bool,
                                          _ groupState: TimelineItemGroupState) -> RoomTimelineItemProtocol {
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
                                       sender: sender,
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
                                            _ sender: TimelineItemSender,
                                            _ isOutgoing: Bool,
                                            _ groupState: TimelineItemGroupState) -> RoomTimelineItemProtocol {
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
                                         sender: sender,
                                         properties: RoomTimelineItemProperties())
    }
    
    private func buildRedactedTimelineItem(_ eventItemProxy: EventTimelineItemProxy,
                                           _ sender: TimelineItemSender,
                                           _ isOutgoing: Bool,
                                           _ groupState: TimelineItemGroupState) -> RoomTimelineItemProtocol {
        RedactedRoomTimelineItem(id: eventItemProxy.id,
                                 text: ElementL10n.eventRedacted,
                                 timestamp: eventItemProxy.timestamp.formatted(date: .omitted, time: .shortened),
                                 groupState: groupState,
                                 isOutgoing: isOutgoing,
                                 isEditable: eventItemProxy.isEditable,
                                 sender: sender,
                                 properties: RoomTimelineItemProperties())
    }

    private func buildFallbackTimelineItem(_ eventItemProxy: EventTimelineItemProxy,
                                           _ sender: TimelineItemSender,
                                           _ isOutgoing: Bool,
                                           _ groupState: TimelineItemGroupState) -> RoomTimelineItemProtocol {
        let attributedText = attributedStringBuilder.fromPlain(eventItemProxy.body)
        let attributedComponents = attributedStringBuilder.blockquoteCoalescedComponentsFrom(attributedText)
        
        return TextRoomTimelineItem(id: eventItemProxy.id,
                                    text: eventItemProxy.body ?? "",
                                    attributedComponents: attributedComponents,
                                    timestamp: eventItemProxy.timestamp.formatted(date: .omitted, time: .shortened),
                                    groupState: groupState,
                                    isOutgoing: isOutgoing,
                                    isEditable: eventItemProxy.isEditable,
                                    sender: sender,
                                    properties: RoomTimelineItemProperties(isEdited: eventItemProxy.content.asMessage()?.isEdited() ?? false,
                                                                           reactions: aggregateReactions(eventItemProxy.reactions)))
    }
    
    private func buildTextTimelineItemFromMessage(_ eventItemProxy: EventTimelineItemProxy,
                                                  _ message: MessageTimelineItem<TextMessageContent>,
                                                  _ sender: TimelineItemSender,
                                                  _ isOutgoing: Bool,
                                                  _ groupState: TimelineItemGroupState) -> RoomTimelineItemProtocol {
        let attributedText = (message.htmlBody != nil ? attributedStringBuilder.fromHTML(message.htmlBody) : attributedStringBuilder.fromPlain(message.body))
        let attributedComponents = attributedStringBuilder.blockquoteCoalescedComponentsFrom(attributedText)
        
        return TextRoomTimelineItem(id: message.id,
                                    text: message.body,
                                    attributedComponents: attributedComponents,
                                    timestamp: message.timestamp.formatted(date: .omitted, time: .shortened),
                                    groupState: groupState,
                                    isOutgoing: isOutgoing,
                                    isEditable: eventItemProxy.isEditable,
                                    sender: sender,
                                    properties: RoomTimelineItemProperties(isEdited: message.isEdited,
                                                                           reactions: aggregateReactions(eventItemProxy.reactions),
                                                                           deliveryStatus: eventItemProxy.deliveryStatus))
    }
    
    private func buildImageTimelineItemFromMessage(_ eventItemProxy: EventTimelineItemProxy,
                                                   _ message: MessageTimelineItem<ImageMessageContent>,
                                                   _ sender: TimelineItemSender,
                                                   _ isOutgoing: Bool,
                                                   _ groupState: TimelineItemGroupState) -> RoomTimelineItemProtocol {
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
                                     sender: sender,
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
                                                   _ sender: TimelineItemSender,
                                                   _ isOutgoing: Bool,
                                                   _ groupState: TimelineItemGroupState) -> RoomTimelineItemProtocol {
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
                                     sender: sender,
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
                                                  _ sender: TimelineItemSender,
                                                  _ isOutgoing: Bool,
                                                  _ groupState: TimelineItemGroupState) -> RoomTimelineItemProtocol {
        FileRoomTimelineItem(id: message.id,
                             text: message.body,
                             timestamp: message.timestamp.formatted(date: .omitted, time: .shortened),
                             groupState: groupState,
                             isOutgoing: isOutgoing,
                             isEditable: eventItemProxy.isEditable,
                             sender: sender,
                             source: message.source,
                             thumbnailSource: message.thumbnailSource,
                             properties: RoomTimelineItemProperties(isEdited: message.isEdited,
                                                                    reactions: aggregateReactions(eventItemProxy.reactions),
                                                                    deliveryStatus: eventItemProxy.deliveryStatus))
    }
    
    private func buildNoticeTimelineItemFromMessage(_ eventItemProxy: EventTimelineItemProxy,
                                                    _ message: MessageTimelineItem<NoticeMessageContent>,
                                                    _ sender: TimelineItemSender,
                                                    _ isOutgoing: Bool,
                                                    _ groupState: TimelineItemGroupState) -> RoomTimelineItemProtocol {
        let attributedText = (message.htmlBody != nil ? attributedStringBuilder.fromHTML(message.htmlBody) : attributedStringBuilder.fromPlain(message.body))
        let attributedComponents = attributedStringBuilder.blockquoteCoalescedComponentsFrom(attributedText)
        
        return NoticeRoomTimelineItem(id: message.id,
                                      text: message.body,
                                      attributedComponents: attributedComponents,
                                      timestamp: message.timestamp.formatted(date: .omitted, time: .shortened),
                                      groupState: groupState,
                                      isOutgoing: isOutgoing,
                                      isEditable: eventItemProxy.isEditable,
                                      sender: sender,
                                      properties: RoomTimelineItemProperties(isEdited: message.isEdited,
                                                                             reactions: aggregateReactions(eventItemProxy.reactions),
                                                                             deliveryStatus: eventItemProxy.deliveryStatus))
    }
    
    private func buildEmoteTimelineItemFromMessage(_ eventItemProxy: EventTimelineItemProxy,
                                                   _ message: MessageTimelineItem<EmoteMessageContent>,
                                                   _ sender: TimelineItemSender,
                                                   _ isOutgoing: Bool,
                                                   _ groupState: TimelineItemGroupState) -> RoomTimelineItemProtocol {
        let name = sender.displayName ?? sender.id

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
                                     sender: sender,
                                     properties: RoomTimelineItemProperties(isEdited: message.isEdited,
                                                                            reactions: aggregateReactions(eventItemProxy.reactions),
                                                                            deliveryStatus: eventItemProxy.deliveryStatus))
    }
    
    private func aggregateReactions(_ reactions: [Reaction]) -> [AggregatedReaction] {
        reactions.map { reaction in
            let isHighlighted = false // reaction.details.contains(where: { $0.sender.id == userID })
            return AggregatedReaction(key: reaction.key, count: Int(reaction.count), isHighlighted: isHighlighted)
        }
    }
    
    // MARK: - State Events
    
    private func buildStateTimelineItemFor(eventItemProxy: EventTimelineItemProxy,
                                           content: OtherState,
                                           stateKey: String,
                                           sender: TimelineItemSender,
                                           isOutgoing: Bool) -> RoomTimelineItemProtocol? {
        guard let text = roomStateTimelineItemFactory.textForOtherState(content, stateKey: stateKey, sender: sender, isOutgoing: isOutgoing) else { return nil }
        return buildStateTimelineItem(eventItemProxy: eventItemProxy, text: text, sender: sender, isOutgoing: isOutgoing)
    }
    
    private func buildStateMembershipChangeTimelineItemFor(eventItemProxy: EventTimelineItemProxy,
                                                           member: String,
                                                           change: MembershipChange,
                                                           sender: TimelineItemSender,
                                                           isOutgoing: Bool) -> RoomTimelineItemProtocol? {
        guard let text = roomStateTimelineItemFactory.textForMembershipChange(change, member: member, sender: eventItemProxy.sender, isOutgoing: isOutgoing) else { return nil }
        return buildStateTimelineItem(eventItemProxy: eventItemProxy, text: text, sender: sender, isOutgoing: isOutgoing)
    }
    
    private func buildStateTimelineItem(eventItemProxy: EventTimelineItemProxy, text: String, sender: TimelineItemSender, isOutgoing: Bool) -> RoomTimelineItemProtocol {
        StateRoomTimelineItem(id: eventItemProxy.id,
                              text: text,
                              timestamp: eventItemProxy.timestamp.formatted(date: .omitted, time: .shortened),
                              groupState: .single,
                              isOutgoing: isOutgoing,
                              isEditable: false,
                              sender: sender)
    }
}

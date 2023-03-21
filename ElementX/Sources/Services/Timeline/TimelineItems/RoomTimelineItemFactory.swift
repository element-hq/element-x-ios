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
    private let stateEventStringBuilder: RoomStateEventStringBuilder
    
    /// The Matrix ID of the current user.
    private let userID: String
    
    init(userID: String,
         mediaProvider: MediaProviderProtocol,
         attributedStringBuilder: AttributedStringBuilderProtocol,
         stateEventStringBuilder: RoomStateEventStringBuilder) {
        self.userID = userID
        self.mediaProvider = mediaProvider
        self.attributedStringBuilder = attributedStringBuilder
        self.stateEventStringBuilder = stateEventStringBuilder
    }
    
    // swiftlint:disable:next cyclomatic_complexity
    func buildTimelineItemFor(eventItemProxy: EventTimelineItemProxy) -> RoomTimelineItemProtocol? {
        let isOutgoing = eventItemProxy.isOwn
        
        switch eventItemProxy.content.kind() {
        case .unableToDecrypt(let encryptedMessage):
            return buildEncryptedTimelineItem(eventItemProxy, encryptedMessage, isOutgoing)
        case .redactedMessage:
            return buildRedactedTimelineItem(eventItemProxy, isOutgoing)
        case .sticker(let body, let imageInfo, let urlString):
            guard let url = URL(string: urlString) else {
                MXLog.error("Invalid sticker url string: \(urlString)")
                return buildUnsupportedTimelineItem(eventItemProxy, "m.sticker", "Invalid Sticker URL", isOutgoing)
            }
            
            return buildStickerTimelineItem(eventItemProxy, body, imageInfo, url, isOutgoing)
        case .failedToParseMessageLike(let eventType, let error):
            return buildUnsupportedTimelineItem(eventItemProxy, eventType, error, isOutgoing)
        case .failedToParseState(let eventType, _, let error):
            return buildUnsupportedTimelineItem(eventItemProxy, eventType, error, isOutgoing)
        case .message:
            guard let messageContent = eventItemProxy.content.asMessage() else { fatalError("Invalid message timeline item: \(eventItemProxy)") }
            
            switch messageContent.msgtype() {
            case .text(content: let content):
                let message = MessageTimelineItem(item: eventItemProxy.item, content: content)
                return buildTextTimelineItemFromMessage(eventItemProxy, message, isOutgoing)
            case .image(content: let content):
                let message = MessageTimelineItem(item: eventItemProxy.item, content: content)
                return buildImageTimelineItemFromMessage(eventItemProxy, message, isOutgoing)
            case .video(let content):
                let message = MessageTimelineItem(item: eventItemProxy.item, content: content)
                return buildVideoTimelineItemFromMessage(eventItemProxy, message, isOutgoing)
            case .file(let content):
                let message = MessageTimelineItem(item: eventItemProxy.item, content: content)
                return buildFileTimelineItemFromMessage(eventItemProxy, message, isOutgoing)
            case .notice(content: let content):
                let message = MessageTimelineItem(item: eventItemProxy.item, content: content)
                return buildNoticeTimelineItemFromMessage(eventItemProxy, message, isOutgoing)
            case .emote(content: let content):
                let message = MessageTimelineItem(item: eventItemProxy.item, content: content)
                return buildEmoteTimelineItemFromMessage(eventItemProxy, message, isOutgoing)
            case .audio(let content):
                let message = MessageTimelineItem(item: eventItemProxy.item, content: content)
                return buildAudioTimelineItem(eventItemProxy, message, isOutgoing)
            case .none:
                return buildFallbackTimelineItem(eventItemProxy, isOutgoing)
            }
        case .state(let stateKey, let content):
            return buildStateTimelineItemFor(eventItemProxy: eventItemProxy, state: content, stateKey: stateKey, isOutgoing: isOutgoing)
        case .roomMembership(userId: let userID, change: let change):
            return buildStateMembershipChangeTimelineItemFor(eventItemProxy: eventItemProxy, member: userID, membershipChange: change, isOutgoing: isOutgoing)
        case .profileChange(let displayName, let prevDisplayName, let avatarUrl, let prevAvatarUrl):
            return buildStateProfileChangeTimelineItemFor(eventItemProxy: eventItemProxy, displayName: displayName, previousDisplayName: prevDisplayName, avatarURLString: avatarUrl, previousAvatarURLString: prevAvatarUrl, isOutgoing: isOutgoing)
        }
    }
    
    // MARK: - Message Events
    
    private func buildUnsupportedTimelineItem(_ eventItemProxy: EventTimelineItemProxy,
                                              _ eventType: String,
                                              _ error: String,
                                              _ isOutgoing: Bool) -> RoomTimelineItemProtocol {
        UnsupportedRoomTimelineItem(id: eventItemProxy.id,
                                    body: L10n.commonUnsupportedEvent,
                                    eventType: eventType,
                                    error: error,
                                    timestamp: eventItemProxy.timestamp.formatted(date: .omitted, time: .shortened),
                                    isOutgoing: isOutgoing,
                                    isEditable: eventItemProxy.isEditable,
                                    sender: eventItemProxy.sender,
                                    properties: RoomTimelineItemProperties())
    }
    
    private func buildStickerTimelineItem(_ eventItemProxy: EventTimelineItemProxy,
                                          _ body: String,
                                          _ imageInfo: ImageInfo,
                                          _ imageURL: URL,
                                          _ isOutgoing: Bool) -> RoomTimelineItemProtocol {
        var aspectRatio: CGFloat?
        let width = imageInfo.width.map(CGFloat.init)
        let height = imageInfo.height.map(CGFloat.init)
        if let width, let height {
            aspectRatio = width / height
        }
        
        return StickerRoomTimelineItem(id: eventItemProxy.id,
                                       body: body,
                                       timestamp: eventItemProxy.timestamp.formatted(date: .omitted, time: .shortened),
                                       isOutgoing: isOutgoing,
                                       isEditable: eventItemProxy.isEditable,
                                       sender: eventItemProxy.sender,
                                       imageURL: imageURL,
                                       width: width,
                                       height: height,
                                       aspectRatio: aspectRatio,
                                       blurhash: imageInfo.blurhash,
                                       properties: RoomTimelineItemProperties(reactions: aggregateReactions(eventItemProxy.reactions),
                                                                              deliveryStatus: eventItemProxy.deliveryStatus))
    }
    
    private func buildEncryptedTimelineItem(_ eventItemProxy: EventTimelineItemProxy,
                                            _ encryptedMessage: EncryptedMessage,
                                            _ isOutgoing: Bool) -> RoomTimelineItemProtocol {
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
                                         body: ElementL10n.roomTimelineUnableToDecrypt,
                                         encryptionType: encryptionType,
                                         timestamp: eventItemProxy.timestamp.formatted(date: .omitted, time: .shortened),
                                         isOutgoing: isOutgoing,
                                         isEditable: eventItemProxy.isEditable,
                                         sender: eventItemProxy.sender,
                                         properties: RoomTimelineItemProperties())
    }
    
    private func buildRedactedTimelineItem(_ eventItemProxy: EventTimelineItemProxy,
                                           _ isOutgoing: Bool) -> RoomTimelineItemProtocol {
        RedactedRoomTimelineItem(id: eventItemProxy.id,
                                 body: ElementL10n.eventRedacted,
                                 timestamp: eventItemProxy.timestamp.formatted(date: .omitted, time: .shortened),
                                 isOutgoing: isOutgoing,
                                 isEditable: eventItemProxy.isEditable,
                                 sender: eventItemProxy.sender,
                                 properties: RoomTimelineItemProperties())
    }

    private func buildFallbackTimelineItem(_ eventItemProxy: EventTimelineItemProxy,
                                           _ isOutgoing: Bool) -> RoomTimelineItemProtocol {
        let formattedBody = attributedStringBuilder.fromPlain(eventItemProxy.body)
        
        return TextRoomTimelineItem(id: eventItemProxy.id,
                                    body: eventItemProxy.body ?? "",
                                    formattedBody: formattedBody,
                                    timestamp: eventItemProxy.timestamp.formatted(date: .omitted, time: .shortened),
                                    isOutgoing: isOutgoing,
                                    isEditable: eventItemProxy.isEditable,
                                    sender: eventItemProxy.sender,
                                    properties: RoomTimelineItemProperties(isEdited: eventItemProxy.content.asMessage()?.isEdited() ?? false,
                                                                           reactions: aggregateReactions(eventItemProxy.reactions)))
    }
    
    private func buildTextTimelineItemFromMessage(_ eventItemProxy: EventTimelineItemProxy,
                                                  _ message: MessageTimelineItem<TextMessageContent>,
                                                  _ isOutgoing: Bool) -> RoomTimelineItemProtocol {
        let formattedBody = (message.htmlBody != nil ? attributedStringBuilder.fromHTML(message.htmlBody) : attributedStringBuilder.fromPlain(message.body))
        
        return TextRoomTimelineItem(id: message.id,
                                    body: message.body,
                                    formattedBody: formattedBody,
                                    timestamp: message.timestamp.formatted(date: .omitted, time: .shortened),
                                    isOutgoing: isOutgoing,
                                    isEditable: eventItemProxy.isEditable,
                                    sender: eventItemProxy.sender,
                                    properties: RoomTimelineItemProperties(isEdited: message.isEdited,
                                                                           reactions: aggregateReactions(eventItemProxy.reactions),
                                                                           deliveryStatus: eventItemProxy.deliveryStatus))
    }
    
    private func buildImageTimelineItemFromMessage(_ eventItemProxy: EventTimelineItemProxy,
                                                   _ message: MessageTimelineItem<ImageMessageContent>,
                                                   _ isOutgoing: Bool) -> RoomTimelineItemProtocol {
        var aspectRatio: CGFloat?
        if let width = message.width,
           let height = message.height {
            aspectRatio = width / height
        }
        
        return ImageRoomTimelineItem(id: message.id,
                                     body: message.body,
                                     timestamp: message.timestamp.formatted(date: .omitted, time: .shortened),
                                     isOutgoing: isOutgoing,
                                     isEditable: eventItemProxy.isEditable,
                                     sender: eventItemProxy.sender,
                                     source: message.source,
                                     width: message.width,
                                     height: message.height,
                                     aspectRatio: aspectRatio,
                                     blurhash: message.blurhash,
                                     contentType: message.contentType,
                                     properties: RoomTimelineItemProperties(isEdited: message.isEdited,
                                                                            reactions: aggregateReactions(eventItemProxy.reactions),
                                                                            deliveryStatus: eventItemProxy.deliveryStatus))
    }
    
    private func buildVideoTimelineItemFromMessage(_ eventItemProxy: EventTimelineItemProxy,
                                                   _ message: MessageTimelineItem<VideoMessageContent>,
                                                   _ isOutgoing: Bool) -> RoomTimelineItemProtocol {
        var aspectRatio: CGFloat?
        if let width = message.width,
           let height = message.height {
            aspectRatio = width / height
        }
        
        return VideoRoomTimelineItem(id: message.id,
                                     body: message.body,
                                     timestamp: message.timestamp.formatted(date: .omitted, time: .shortened),
                                     isOutgoing: isOutgoing,
                                     isEditable: eventItemProxy.isEditable,
                                     sender: eventItemProxy.sender,
                                     duration: message.duration,
                                     source: message.source,
                                     thumbnailSource: message.thumbnailSource,
                                     width: message.width,
                                     height: message.height,
                                     aspectRatio: aspectRatio,
                                     blurhash: message.blurhash,
                                     contentType: message.contentType,
                                     properties: RoomTimelineItemProperties(isEdited: message.isEdited,
                                                                            reactions: aggregateReactions(eventItemProxy.reactions),
                                                                            deliveryStatus: eventItemProxy.deliveryStatus))
    }

    private func buildAudioTimelineItem(_ eventItemProxy: EventTimelineItemProxy,
                                        _ message: MessageTimelineItem<AudioMessageContent>,
                                        _ isOutgoing: Bool) -> RoomTimelineItemProtocol {
        AudioRoomTimelineItem(id: eventItemProxy.id,
                              body: message.body,
                              timestamp: message.timestamp.formatted(date: .omitted, time: .shortened),
                              isOutgoing: isOutgoing,
                              isEditable: eventItemProxy.isEditable,
                              sender: eventItemProxy.sender,
                              duration: message.duration,
                              source: message.source,
                              contentType: message.contentType,
                              properties: RoomTimelineItemProperties(isEdited: message.isEdited,
                                                                     reactions: aggregateReactions(eventItemProxy.reactions),
                                                                     deliveryStatus: eventItemProxy.deliveryStatus))
    }

    private func buildFileTimelineItemFromMessage(_ eventItemProxy: EventTimelineItemProxy,
                                                  _ message: MessageTimelineItem<FileMessageContent>,
                                                  _ isOutgoing: Bool) -> RoomTimelineItemProtocol {
        FileRoomTimelineItem(id: message.id,
                             body: message.body,
                             timestamp: message.timestamp.formatted(date: .omitted, time: .shortened),
                             isOutgoing: isOutgoing,
                             isEditable: eventItemProxy.isEditable,
                             sender: eventItemProxy.sender,
                             source: message.source,
                             thumbnailSource: message.thumbnailSource,
                             contentType: message.contentType,
                             properties: RoomTimelineItemProperties(isEdited: message.isEdited,
                                                                    reactions: aggregateReactions(eventItemProxy.reactions),
                                                                    deliveryStatus: eventItemProxy.deliveryStatus))
    }
    
    private func buildNoticeTimelineItemFromMessage(_ eventItemProxy: EventTimelineItemProxy,
                                                    _ message: MessageTimelineItem<NoticeMessageContent>,
                                                    _ isOutgoing: Bool) -> RoomTimelineItemProtocol {
        let formattedBody = (message.htmlBody != nil ? attributedStringBuilder.fromHTML(message.htmlBody) : attributedStringBuilder.fromPlain(message.body))
        
        return NoticeRoomTimelineItem(id: message.id,
                                      body: message.body,
                                      formattedBody: formattedBody,
                                      timestamp: message.timestamp.formatted(date: .omitted, time: .shortened),
                                      isOutgoing: isOutgoing,
                                      isEditable: eventItemProxy.isEditable,
                                      sender: eventItemProxy.sender,
                                      properties: RoomTimelineItemProperties(isEdited: message.isEdited,
                                                                             reactions: aggregateReactions(eventItemProxy.reactions),
                                                                             deliveryStatus: eventItemProxy.deliveryStatus))
    }
    
    private func buildEmoteTimelineItemFromMessage(_ eventItemProxy: EventTimelineItemProxy,
                                                   _ message: MessageTimelineItem<EmoteMessageContent>,
                                                   _ isOutgoing: Bool) -> RoomTimelineItemProtocol {
        let name = eventItemProxy.sender.displayName ?? eventItemProxy.sender.id

        var formattedBody: AttributedString?
        if let htmlBody = message.htmlBody {
            formattedBody = attributedStringBuilder.fromHTML("* \(name) \(htmlBody)")
        } else {
            formattedBody = attributedStringBuilder.fromPlain("* \(name) \(message.body)")
        }
        
        return EmoteRoomTimelineItem(id: message.id,
                                     body: message.body,
                                     formattedBody: formattedBody,
                                     timestamp: message.timestamp.formatted(date: .omitted, time: .shortened),
                                     isOutgoing: isOutgoing,
                                     isEditable: eventItemProxy.isEditable,
                                     sender: eventItemProxy.sender,
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
                                           state: OtherState,
                                           stateKey: String,
                                           isOutgoing: Bool) -> RoomTimelineItemProtocol? {
        guard let text = stateEventStringBuilder.buildString(for: state, stateKey: stateKey, sender: eventItemProxy.sender, isOutgoing: isOutgoing) else { return nil }
        return buildStateTimelineItem(eventItemProxy: eventItemProxy, text: text, isOutgoing: isOutgoing)
    }
    
    private func buildStateMembershipChangeTimelineItemFor(eventItemProxy: EventTimelineItemProxy,
                                                           member: String,
                                                           membershipChange: MembershipChange?,
                                                           isOutgoing: Bool) -> RoomTimelineItemProtocol? {
        guard let text = stateEventStringBuilder.buildString(for: membershipChange, member: member, sender: eventItemProxy.sender, isOutgoing: isOutgoing) else { return nil }
        return buildStateTimelineItem(eventItemProxy: eventItemProxy, text: text, isOutgoing: isOutgoing)
    }
    
    // swiftlint:disable:next function_parameter_count
    private func buildStateProfileChangeTimelineItemFor(eventItemProxy: EventTimelineItemProxy,
                                                        displayName: String?,
                                                        previousDisplayName: String?,
                                                        avatarURLString: String?,
                                                        previousAvatarURLString: String?,
                                                        isOutgoing: Bool) -> RoomTimelineItemProtocol? {
        guard let text = stateEventStringBuilder.buildProfileChangeString(displayName: displayName,
                                                                          previousDisplayName: previousDisplayName,
                                                                          avatarURLString: avatarURLString,
                                                                          previousAvatarURLString: previousAvatarURLString,
                                                                          member: eventItemProxy.sender.id,
                                                                          memberIsYou: isOutgoing) else { return nil }
        return buildStateTimelineItem(eventItemProxy: eventItemProxy, text: text, isOutgoing: isOutgoing)
    }
    
    private func buildStateTimelineItem(eventItemProxy: EventTimelineItemProxy, text: String, isOutgoing: Bool) -> RoomTimelineItemProtocol {
        StateRoomTimelineItem(id: eventItemProxy.id,
                              body: text,
                              timestamp: eventItemProxy.timestamp.formatted(date: .omitted, time: .shortened),
                              isOutgoing: isOutgoing,
                              isEditable: false,
                              sender: eventItemProxy.sender)
    }
}

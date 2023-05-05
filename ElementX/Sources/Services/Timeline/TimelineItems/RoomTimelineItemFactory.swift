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
import UniformTypeIdentifiers

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
    func buildTimelineItemFor(eventTimelineItem: EventTimelineItemProxy) -> RoomTimelineItemProtocol? {
        let isOutgoing = eventTimelineItem.isOwn
        
        switch eventTimelineItem.content.kind() {
        case .unableToDecrypt(let encryptedMessage):
            return buildEncryptedTimelineItem(eventTimelineItem, encryptedMessage, isOutgoing)
        case .redactedMessage:
            return buildRedactedTimelineItem(eventTimelineItem, isOutgoing)
        case .sticker(let body, let imageInfo, let urlString):
            guard let url = URL(string: urlString) else {
                MXLog.error("Invalid sticker url string: \(urlString)")
                return buildUnsupportedTimelineItem(eventTimelineItem, "m.sticker", "Invalid Sticker URL", isOutgoing)
            }
            
            return buildStickerTimelineItem(eventTimelineItem, body, imageInfo, url, isOutgoing)
        case .failedToParseMessageLike(let eventType, let error):
            return buildUnsupportedTimelineItem(eventTimelineItem, eventType, error, isOutgoing)
        case .failedToParseState(let eventType, _, let error):
            return buildUnsupportedTimelineItem(eventTimelineItem, eventType, error, isOutgoing)
        case .message:
            guard let messageTimelineItem = eventTimelineItem.content.asMessage() else { fatalError("Invalid message timeline item: \(eventTimelineItem)") }
            
            switch messageTimelineItem.msgtype() {
            case .text(content: let content):
                return buildTextTimelineItemFromMessage(eventTimelineItem, messageTimelineItem, content, isOutgoing)
            case .image(content: let content):
                return buildImageTimelineItemFromMessage(eventTimelineItem, messageTimelineItem, content, isOutgoing)
            case .video(let content):
                return buildVideoTimelineItemFromMessage(eventTimelineItem, messageTimelineItem, content, isOutgoing)
            case .file(let content):
                return buildFileTimelineItemFromMessage(eventTimelineItem, messageTimelineItem, content, isOutgoing)
            case .notice(content: let content):
                return buildNoticeTimelineItemFromMessage(eventTimelineItem, messageTimelineItem, content, isOutgoing)
            case .emote(content: let content):
                return buildEmoteTimelineItemFromMessage(eventTimelineItem, messageTimelineItem, content, isOutgoing)
            case .audio(let content):
                return buildAudioTimelineItem(eventTimelineItem, messageTimelineItem, content, isOutgoing)
            case .none:
                return buildFallbackTimelineItem(eventTimelineItem, isOutgoing)
            }
        case .state(let stateKey, let content):
            return buildStateTimelineItemFor(eventTimelineItem: eventTimelineItem, state: content, stateKey: stateKey, isOutgoing: isOutgoing)
        case .roomMembership(userId: let userID, change: let change):
            return buildStateMembershipChangeTimelineItemFor(eventTimelineItem: eventTimelineItem, member: userID, membershipChange: change, isOutgoing: isOutgoing)
        case .profileChange(let displayName, let prevDisplayName, let avatarUrl, let prevAvatarUrl):
            return buildStateProfileChangeTimelineItemFor(eventTimelineItem: eventTimelineItem,
                                                          displayName: displayName,
                                                          previousDisplayName: prevDisplayName,
                                                          avatarURLString: avatarUrl,
                                                          previousAvatarURLString: prevAvatarUrl,
                                                          isOutgoing: isOutgoing)
        }
    }
    
    // MARK: - Message Events
    
    private func buildUnsupportedTimelineItem(_ eventTimelineItem: EventTimelineItemProxy,
                                              _ eventType: String,
                                              _ error: String,
                                              _ isOutgoing: Bool) -> RoomTimelineItemProtocol {
        UnsupportedRoomTimelineItem(id: eventTimelineItem.id,
                                    body: L10n.commonUnsupportedEvent,
                                    eventType: eventType,
                                    error: error,
                                    timestamp: eventTimelineItem.timestamp.formatted(date: .omitted, time: .shortened),
                                    isOutgoing: isOutgoing,
                                    isEditable: eventTimelineItem.isEditable,
                                    sender: eventTimelineItem.sender,
                                    properties: RoomTimelineItemProperties())
    }
    
    private func buildStickerTimelineItem(_ eventTimelineItem: EventTimelineItemProxy,
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
        
        return StickerRoomTimelineItem(id: eventTimelineItem.id,
                                       body: body,
                                       timestamp: eventTimelineItem.timestamp.formatted(date: .omitted, time: .shortened),
                                       isOutgoing: isOutgoing,
                                       isEditable: eventTimelineItem.isEditable,
                                       sender: eventTimelineItem.sender,
                                       imageURL: imageURL,
                                       width: width,
                                       height: height,
                                       aspectRatio: aspectRatio,
                                       blurhash: imageInfo.blurhash,
                                       properties: RoomTimelineItemProperties(reactions: aggregateReactions(eventTimelineItem.reactions),
                                                                              deliveryStatus: eventTimelineItem.deliveryStatus))
    }
    
    private func buildEncryptedTimelineItem(_ eventTimelineItem: EventTimelineItemProxy,
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
        
        return EncryptedRoomTimelineItem(id: eventTimelineItem.id,
                                         body: L10n.commonUnableToDecrypt,
                                         encryptionType: encryptionType,
                                         timestamp: eventTimelineItem.timestamp.formatted(date: .omitted, time: .shortened),
                                         isOutgoing: isOutgoing,
                                         isEditable: eventTimelineItem.isEditable,
                                         sender: eventTimelineItem.sender,
                                         properties: RoomTimelineItemProperties())
    }
    
    private func buildRedactedTimelineItem(_ eventTimelineItem: EventTimelineItemProxy,
                                           _ isOutgoing: Bool) -> RoomTimelineItemProtocol {
        RedactedRoomTimelineItem(id: eventTimelineItem.id,
                                 body: L10n.commonMessageRemoved,
                                 timestamp: eventTimelineItem.timestamp.formatted(date: .omitted, time: .shortened),
                                 isOutgoing: isOutgoing,
                                 isEditable: eventTimelineItem.isEditable,
                                 sender: eventTimelineItem.sender,
                                 properties: RoomTimelineItemProperties())
    }
    
    private func buildFallbackTimelineItem(_ eventTimelineItem: EventTimelineItemProxy,
                                           _ isOutgoing: Bool) -> RoomTimelineItemProtocol {
        TextRoomTimelineItem(id: eventTimelineItem.id,
                             timestamp: eventTimelineItem.timestamp.formatted(date: .omitted, time: .shortened),
                             isOutgoing: isOutgoing,
                             isEditable: eventTimelineItem.isEditable,
                             sender: eventTimelineItem.sender,
                             content: .init(body: "Unknown timeline item"),
                             replyDetails: nil,
                             properties: RoomTimelineItemProperties(isEdited: false,
                                                                    reactions: aggregateReactions(eventTimelineItem.reactions)))
    }
    
    private func buildTextTimelineItemFromMessage(_ eventTimelineItem: EventTimelineItemProxy,
                                                  _ messageTimelineItem: Message,
                                                  _ messageContent: TextMessageContent,
                                                  _ isOutgoing: Bool) -> RoomTimelineItemProtocol {
        TextRoomTimelineItem(id: eventTimelineItem.id,
                             timestamp: eventTimelineItem.timestamp.formatted(date: .omitted, time: .shortened),
                             isOutgoing: isOutgoing,
                             isEditable: eventTimelineItem.isEditable,
                             sender: eventTimelineItem.sender,
                             content: buildTextTimelineItemContent(messageContent),
                             replyDetails: buildReplyToDetailsFrom(details: messageTimelineItem.inReplyTo()),
                             properties: RoomTimelineItemProperties(isEdited: messageTimelineItem.isEdited(),
                                                                    reactions: aggregateReactions(eventTimelineItem.reactions),
                                                                    deliveryStatus: eventTimelineItem.deliveryStatus))
    }
    
    private func buildImageTimelineItemFromMessage(_ eventTimelineItem: EventTimelineItemProxy,
                                                   _ messageTimelineItem: Message,
                                                   _ messageContent: ImageMessageContent,
                                                   _ isOutgoing: Bool) -> RoomTimelineItemProtocol {
        ImageRoomTimelineItem(id: eventTimelineItem.id,
                              timestamp: eventTimelineItem.timestamp.formatted(date: .omitted, time: .shortened),
                              isOutgoing: isOutgoing,
                              isEditable: eventTimelineItem.isEditable,
                              sender: eventTimelineItem.sender,
                              content: buildImageTimelineItemContent(messageContent),
                              replyDetails: buildReplyToDetailsFrom(details: messageTimelineItem.inReplyTo()),
                              properties: RoomTimelineItemProperties(isEdited: messageTimelineItem.isEdited(),
                                                                     reactions: aggregateReactions(eventTimelineItem.reactions),
                                                                     deliveryStatus: eventTimelineItem.deliveryStatus))
    }
    
    private func buildVideoTimelineItemFromMessage(_ eventTimelineItem: EventTimelineItemProxy,
                                                   _ messageTimelineItem: Message,
                                                   _ messageContent: VideoMessageContent,
                                                   _ isOutgoing: Bool) -> RoomTimelineItemProtocol {
        VideoRoomTimelineItem(id: eventTimelineItem.id,
                              timestamp: eventTimelineItem.timestamp.formatted(date: .omitted, time: .shortened),
                              isOutgoing: isOutgoing,
                              isEditable: eventTimelineItem.isEditable,
                              sender: eventTimelineItem.sender,
                              content: buildVideoTimelineItemContent(messageContent),
                              replyDetails: buildReplyToDetailsFrom(details: messageTimelineItem.inReplyTo()),
                              properties: RoomTimelineItemProperties(isEdited: messageTimelineItem.isEdited(),
                                                                     reactions: aggregateReactions(eventTimelineItem.reactions),
                                                                     deliveryStatus: eventTimelineItem.deliveryStatus))
    }
    
    private func buildAudioTimelineItem(_ eventTimelineItem: EventTimelineItemProxy,
                                        _ messageTimelineItem: Message,
                                        _ messageContent: AudioMessageContent,
                                        _ isOutgoing: Bool) -> RoomTimelineItemProtocol {
        AudioRoomTimelineItem(id: eventTimelineItem.id,
                              timestamp: eventTimelineItem.timestamp.formatted(date: .omitted, time: .shortened),
                              isOutgoing: isOutgoing,
                              isEditable: eventTimelineItem.isEditable,
                              sender: eventTimelineItem.sender,
                              content: buildAudioTimelineItemContent(messageContent),
                              replyDetails: buildReplyToDetailsFrom(details: messageTimelineItem.inReplyTo()),
                              properties: RoomTimelineItemProperties(isEdited: messageTimelineItem.isEdited(),
                                                                     reactions: aggregateReactions(eventTimelineItem.reactions),
                                                                     deliveryStatus: eventTimelineItem.deliveryStatus))
    }
    
    private func buildFileTimelineItemFromMessage(_ eventTimelineItem: EventTimelineItemProxy,
                                                  _ messageTimelineItem: Message,
                                                  _ messageContent: FileMessageContent,
                                                  _ isOutgoing: Bool) -> RoomTimelineItemProtocol {
        FileRoomTimelineItem(id: eventTimelineItem.id,
                             timestamp: eventTimelineItem.timestamp.formatted(date: .omitted, time: .shortened),
                             isOutgoing: isOutgoing,
                             isEditable: eventTimelineItem.isEditable,
                             sender: eventTimelineItem.sender,
                             content: buildFileTimelineItemContent(messageContent),
                             replyDetails: buildReplyToDetailsFrom(details: messageTimelineItem.inReplyTo()),
                             properties: RoomTimelineItemProperties(isEdited: messageTimelineItem.isEdited(),
                                                                    reactions: aggregateReactions(eventTimelineItem.reactions),
                                                                    deliveryStatus: eventTimelineItem.deliveryStatus))
    }
    
    private func buildNoticeTimelineItemFromMessage(_ eventTimelineItem: EventTimelineItemProxy,
                                                    _ messageTimelineItem: Message,
                                                    _ messageContent: NoticeMessageContent,
                                                    _ isOutgoing: Bool) -> RoomTimelineItemProtocol {
        NoticeRoomTimelineItem(id: eventTimelineItem.id,
                               timestamp: eventTimelineItem.timestamp.formatted(date: .omitted, time: .shortened),
                               isOutgoing: isOutgoing,
                               isEditable: eventTimelineItem.isEditable,
                               sender: eventTimelineItem.sender,
                               content: buildNoticeTimelineItemContent(messageContent),
                               replyDetails: buildReplyToDetailsFrom(details: messageTimelineItem.inReplyTo()),
                               properties: RoomTimelineItemProperties(isEdited: messageTimelineItem.isEdited(),
                                                                      reactions: aggregateReactions(eventTimelineItem.reactions),
                                                                      deliveryStatus: eventTimelineItem.deliveryStatus))
    }
    
    private func buildEmoteTimelineItemFromMessage(_ eventTimelineItem: EventTimelineItemProxy,
                                                   _ messageTimelineItem: Message,
                                                   _ messageContent: EmoteMessageContent,
                                                   _ isOutgoing: Bool) -> RoomTimelineItemProtocol {
        EmoteRoomTimelineItem(id: eventTimelineItem.id,
                              timestamp: eventTimelineItem.timestamp.formatted(date: .omitted, time: .shortened),
                              isOutgoing: isOutgoing,
                              isEditable: eventTimelineItem.isEditable,
                              sender: eventTimelineItem.sender,
                              content: buildEmoteTimelineItemContent(senderDisplayName: eventTimelineItem.sender.displayName, senderID: eventTimelineItem.sender.id, messageContent: messageContent),
                              replyDetails: buildReplyToDetailsFrom(details: messageTimelineItem.inReplyTo()),
                              properties: RoomTimelineItemProperties(isEdited: messageTimelineItem.isEdited(),
                                                                     reactions: aggregateReactions(eventTimelineItem.reactions),
                                                                     deliveryStatus: eventTimelineItem.deliveryStatus))
    }
    
    private func aggregateReactions(_ reactions: [Reaction]) -> [AggregatedReaction] {
        reactions.map { reaction in
            let isHighlighted = false // reaction.details.contains(where: { $0.sender.id == userID })
            return AggregatedReaction(key: reaction.key, count: Int(reaction.count), isHighlighted: isHighlighted)
        }
    }
    
    // MARK: - Message events content
    
    private func buildTextTimelineItemContent(_ messageContent: TextMessageContent) -> TextRoomTimelineItemContent {
        let htmlBody = messageContent.formatted?.format == .html ? messageContent.formatted?.body : nil
        let formattedBody = (htmlBody != nil ? attributedStringBuilder.fromHTML(htmlBody) : attributedStringBuilder.fromPlain(messageContent.body))
        
        return .init(body: messageContent.body, formattedBody: formattedBody)
    }
    
    private func buildAudioTimelineItemContent(_ messageContent: AudioMessageContent) -> AudioRoomTimelineItemContent {
        AudioRoomTimelineItemContent(body: messageContent.body,
                                     duration: messageContent.info?.duration ?? 0,
                                     source: MediaSourceProxy(source: messageContent.source, mimeType: messageContent.info?.mimetype),
                                     contentType: UTType(mimeType: messageContent.info?.mimetype, fallbackFilename: messageContent.body))
    }
    
    private func buildImageTimelineItemContent(_ messageContent: ImageMessageContent) -> ImageRoomTimelineItemContent {
        var thumbnailSource: MediaSourceProxy?
        if let source = messageContent.info?.thumbnailSource {
            thumbnailSource = MediaSourceProxy(source: source, mimeType: messageContent.info?.thumbnailInfo?.mimetype)
        }
        
        let width = messageContent.info?.width.map(CGFloat.init)
        let height = messageContent.info?.height.map(CGFloat.init)
        
        var aspectRatio: CGFloat?
        if let width, let height {
            aspectRatio = width / height
        }
        
        return .init(body: messageContent.body,
                     source: MediaSourceProxy(source: messageContent.source, mimeType: messageContent.info?.mimetype),
                     thumbnailSource: thumbnailSource,
                     width: width,
                     height: height,
                     aspectRatio: aspectRatio,
                     blurhash: messageContent.info?.blurhash,
                     contentType: UTType(mimeType: messageContent.info?.mimetype, fallbackFilename: messageContent.body))
    }
    
    private func buildVideoTimelineItemContent(_ messageContent: VideoMessageContent) -> VideoRoomTimelineItemContent {
        var thumbnailSource: MediaSourceProxy?
        if let source = messageContent.info?.thumbnailSource {
            thumbnailSource = MediaSourceProxy(source: source, mimeType: messageContent.info?.thumbnailInfo?.mimetype)
        }
        
        let width = messageContent.info?.width.map(CGFloat.init)
        let height = messageContent.info?.height.map(CGFloat.init)
        
        var aspectRatio: CGFloat?
        if let width, let height {
            aspectRatio = width / height
        }
        
        return .init(body: messageContent.body,
                     duration: messageContent.info?.duration ?? 0,
                     source: MediaSourceProxy(source: messageContent.source, mimeType: messageContent.info?.mimetype),
                     thumbnailSource: thumbnailSource,
                     width: width,
                     height: height,
                     aspectRatio: aspectRatio,
                     blurhash: messageContent.info?.blurhash,
                     contentType: UTType(mimeType: messageContent.info?.mimetype, fallbackFilename: messageContent.body))
    }
    
    private func buildFileTimelineItemContent(_ messageContent: FileMessageContent) -> FileRoomTimelineItemContent {
        var thumbnailSource: MediaSourceProxy?
        if let source = messageContent.info?.thumbnailSource {
            thumbnailSource = MediaSourceProxy(source: source, mimeType: messageContent.info?.thumbnailInfo?.mimetype)
        }
        
        return .init(body: messageContent.body,
                     source: MediaSourceProxy(source: messageContent.source, mimeType: messageContent.info?.mimetype),
                     thumbnailSource: thumbnailSource,
                     contentType: UTType(mimeType: messageContent.info?.mimetype, fallbackFilename: messageContent.body))
    }
    
    private func buildNoticeTimelineItemContent(_ messageContent: NoticeMessageContent) -> NoticeRoomTimelineItemContent {
        let htmlBody = messageContent.formatted?.format == .html ? messageContent.formatted?.body : nil
        let formattedBody = (htmlBody != nil ? attributedStringBuilder.fromHTML(htmlBody) : attributedStringBuilder.fromPlain(messageContent.body))
        
        return .init(body: messageContent.body, formattedBody: formattedBody)
    }
    
    private func buildEmoteTimelineItemContent(senderDisplayName: String?, senderID: String, messageContent: EmoteMessageContent) -> EmoteRoomTimelineItemContent {
        let name = senderDisplayName ?? senderID
        
        let htmlBody = messageContent.formatted?.format == .html ? messageContent.formatted?.body : nil

        var formattedBody: AttributedString?
        if let htmlBody {
            formattedBody = attributedStringBuilder.fromHTML("* \(name) \(htmlBody)")
        } else {
            formattedBody = attributedStringBuilder.fromPlain("* \(name) \(messageContent.body)")
        }
        
        return .init(body: messageContent.body, formattedBody: formattedBody)
    }
    
    // MARK: - State Events
    
    private func buildStateTimelineItemFor(eventTimelineItem: EventTimelineItemProxy,
                                           state: OtherState,
                                           stateKey: String,
                                           isOutgoing: Bool) -> RoomTimelineItemProtocol? {
        guard let text = stateEventStringBuilder.buildString(for: state, stateKey: stateKey, sender: eventTimelineItem.sender, isOutgoing: isOutgoing) else { return nil }
        return buildStateTimelineItem(eventTimelineItem: eventTimelineItem, text: text, isOutgoing: isOutgoing)
    }
    
    private func buildStateMembershipChangeTimelineItemFor(eventTimelineItem: EventTimelineItemProxy,
                                                           member: String,
                                                           membershipChange: MembershipChange?,
                                                           isOutgoing: Bool) -> RoomTimelineItemProtocol? {
        guard let text = stateEventStringBuilder.buildString(for: membershipChange, member: member, sender: eventTimelineItem.sender, isOutgoing: isOutgoing) else { return nil }
        return buildStateTimelineItem(eventTimelineItem: eventTimelineItem, text: text, isOutgoing: isOutgoing)
    }
    
    // swiftlint:disable:next function_parameter_count
    private func buildStateProfileChangeTimelineItemFor(eventTimelineItem: EventTimelineItemProxy,
                                                        displayName: String?,
                                                        previousDisplayName: String?,
                                                        avatarURLString: String?,
                                                        previousAvatarURLString: String?,
                                                        isOutgoing: Bool) -> RoomTimelineItemProtocol? {
        guard let text = stateEventStringBuilder.buildProfileChangeString(displayName: displayName,
                                                                          previousDisplayName: previousDisplayName,
                                                                          avatarURLString: avatarURLString,
                                                                          previousAvatarURLString: previousAvatarURLString,
                                                                          member: eventTimelineItem.sender.id,
                                                                          memberIsYou: isOutgoing) else { return nil }
        return buildStateTimelineItem(eventTimelineItem: eventTimelineItem, text: text, isOutgoing: isOutgoing)
    }
    
    private func buildStateTimelineItem(eventTimelineItem: EventTimelineItemProxy, text: String, isOutgoing: Bool) -> RoomTimelineItemProtocol {
        StateRoomTimelineItem(id: eventTimelineItem.id,
                              body: text,
                              timestamp: eventTimelineItem.timestamp.formatted(date: .omitted, time: .shortened),
                              isOutgoing: isOutgoing,
                              isEditable: false,
                              sender: eventTimelineItem.sender)
    }
    
    // MARK: - Reply details
    
    // swiftlint:disable:next cyclomatic_complexity
    private func buildReplyToDetailsFrom(details: InReplyToDetails?) -> TimelineItemReplyDetails? {
        guard let details else { return nil }
        
        switch details.event {
        case .unavailable:
            return .unavailable(eventID: details.eventId)
        case .pending:
            return .pending(eventID: details.eventId)
        case let .ready(message, senderID, senderProfile):
            let sender: TimelineItemSender
            switch senderProfile {
            case let .ready(displayName, _, avatarUrl):
                sender = TimelineItemSender(id: senderID,
                                            displayName: displayName,
                                            avatarURL: avatarUrl.flatMap(URL.init(string:)))
            default:
                sender = TimelineItemSender(id: senderID,
                                            displayName: nil,
                                            avatarURL: nil)
            }
            
            let replyContent: TimelineItemReplyContent
            switch message.msgtype() {
            case .audio(let content):
                replyContent = .audio(buildAudioTimelineItemContent(content))
            case .emote(let content):
                replyContent = .emote(buildEmoteTimelineItemContent(senderDisplayName: sender.displayName, senderID: sender.id, messageContent: content))
            case .file(let content):
                replyContent = .file(buildFileTimelineItemContent(content))
            case .image(let content):
                replyContent = .image(buildImageTimelineItemContent(content))
            case .notice(let content):
                replyContent = .notice(buildNoticeTimelineItemContent(content))
            case .text(let content):
                replyContent = .text(buildTextTimelineItemContent(content))
            case .video(let content):
                replyContent = .video(buildVideoTimelineItemContent(content))
            case .none:
                replyContent = .text(TextRoomTimelineItemContent(body: "Unkown reply content"))
            }
            
            return .ready(sender: sender, content: replyContent)
        case let .error(message):
            return .error(eventID: details.eventId, message: message)
        }
    }
}

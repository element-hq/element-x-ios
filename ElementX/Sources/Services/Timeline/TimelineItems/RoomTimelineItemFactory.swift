//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import MatrixRustSDK
import UIKit
import UniformTypeIdentifiers

struct RoomTimelineItemFactory: RoomTimelineItemFactoryProtocol {
    private let attributedStringBuilder: AttributedStringBuilderProtocol
    private let stateEventStringBuilder: RoomStateEventStringBuilder
    
    /// The Matrix ID of the current user.
    private let userID: String
    
    init(userID: String,
         attributedStringBuilder: AttributedStringBuilderProtocol,
         stateEventStringBuilder: RoomStateEventStringBuilder) {
        self.userID = userID
        self.attributedStringBuilder = attributedStringBuilder
        self.stateEventStringBuilder = stateEventStringBuilder
    }
    
    func buildTimelineItem(for eventItemProxy: EventTimelineItemProxy, isDM: Bool) -> RoomTimelineItemProtocol? {
        let isOutgoing = eventItemProxy.isOwn
        
        switch eventItemProxy.content {
        case .msgLike(let messageLikeContent):
            switch messageLikeContent.kind {
            case .message(let messageContent):
                return buildMessageTimelineItem(eventItemProxy, messageLikeContent, messageContent, isOutgoing)
            case .sticker(let body, let imageInfo, let mediaSource):
                return buildStickerTimelineItem(eventItemProxy, messageLikeContent, body, imageInfo, mediaSource, isOutgoing)
            case .poll(question: let question, kind: let kind, maxSelections: let maxSelections, answers: let answers, votes: let votes, endTime: let endTime, let edited):
                return buildPollTimelineItem(eventItemProxy, messageLikeContent, question, kind, maxSelections, answers, votes, endTime, isOutgoing, edited)
            case .redacted:
                return buildRedactedTimelineItem(eventItemProxy, messageLikeContent, isOutgoing)
            case .unableToDecrypt(let encryptedMessage):
                return buildEncryptedTimelineItem(eventItemProxy, messageLikeContent, encryptedMessage, isOutgoing)
            case .other:
                return nil // We shouldn't receive these without asking for custom event types.
            }
        case .failedToParseMessageLike(let eventType, let error):
            return buildUnsupportedTimelineItem(eventItemProxy, eventType, error, isOutgoing)
        case .failedToParseState(let eventType, _, let error):
            return buildUnsupportedTimelineItem(eventItemProxy, eventType, error, isOutgoing)
        case .state(_, let content):
            if isDM, case .roomCreate = content {
                return nil
            }
            return buildStateTimelineItem(for: eventItemProxy, state: content, isOutgoing: isOutgoing)
        case .roomMembership(userId: let userID, let displayName, change: let change, let reason):
            if isDM, change == .joined, userID == self.userID {
                return nil
            }
            return buildStateMembershipChangeTimelineItem(for: eventItemProxy, memberUserID: userID, memberDisplayName: displayName, membershipChange: change, reason: reason, isOutgoing: isOutgoing)
        case .profileChange(let displayName, let prevDisplayName, let avatarUrl, let prevAvatarUrl):
            return buildStateProfileChangeTimelineItem(for: eventItemProxy,
                                                       displayName: displayName,
                                                       previousDisplayName: prevDisplayName,
                                                       avatarURLString: avatarUrl,
                                                       previousAvatarURLString: prevAvatarUrl,
                                                       isOutgoing: isOutgoing)
        case .callInvite:
            return buildCallInviteTimelineItem(for: eventItemProxy)
        case .rtcNotification:
            return buildCallNotificationTimelineItem(for: eventItemProxy)
        }
    }
    
    // MARK: - MsgLike Events
    
    private func buildMessageTimelineItem(_ eventItemProxy: EventTimelineItemProxy,
                                          _ messageLikeContent: MsgLikeContent,
                                          _ messageContent: MessageContent,
                                          _ isOutgoing: Bool) -> RoomTimelineItemProtocol? {
        switch messageContent.msgType {
        case .text(content: let textMessageContent):
            return buildTextTimelineItem(for: eventItemProxy, messageLikeContent, messageContent, textMessageContent, isOutgoing)
        case .image(content: let imageMessageContent):
            return buildImageTimelineItem(for: eventItemProxy, messageLikeContent, messageContent, imageMessageContent, isOutgoing)
        case .video(let videoMessageContent):
            return buildVideoTimelineItem(for: eventItemProxy, messageLikeContent, messageContent, videoMessageContent, isOutgoing)
        case .file(let fileMessageContent):
            return buildFileTimelineItem(for: eventItemProxy, messageLikeContent, messageContent, fileMessageContent, isOutgoing)
        case .notice(content: let noticeMessageContent):
            return buildNoticeTimelineItem(for: eventItemProxy, messageLikeContent, messageContent, noticeMessageContent, isOutgoing)
        case .emote(content: let emoteMessageContent):
            return buildEmoteTimelineItem(for: eventItemProxy, messageLikeContent, messageContent, emoteMessageContent, isOutgoing)
        case .audio(let audioMessageContent):
            if audioMessageContent.voice != nil {
                return buildVoiceTimelineItem(for: eventItemProxy, messageLikeContent, messageContent, audioMessageContent, isOutgoing)
            } else {
                return buildAudioTimelineItem(for: eventItemProxy, messageLikeContent, messageContent, audioMessageContent, isOutgoing)
            }
        case .location(let locationMessageContent):
            return buildLocationTimelineItem(for: eventItemProxy, messageLikeContent, messageContent, locationMessageContent, isOutgoing)
        case .gallery(let galleryMessageContent):
            return buildGalleryTimelineItem(for: eventItemProxy, messageLikeContent, messageContent, galleryMessageContent, isOutgoing)
        case .other:
            return nil
        }
    }
    
    private func buildTextTimelineItem(for eventItemProxy: EventTimelineItemProxy,
                                       _ messageLikeContent: MsgLikeContent,
                                       _ messageContent: MessageContent,
                                       _ textMessageContent: TextMessageContent,
                                       _ isOutgoing: Bool) -> RoomTimelineItemProtocol {
        TextRoomTimelineItem(id: eventItemProxy.id,
                             timestamp: eventItemProxy.timestamp,
                             isOutgoing: isOutgoing,
                             isEditable: eventItemProxy.isEditable,
                             canBeRepliedTo: eventItemProxy.canBeRepliedTo,
                             shouldBoost: eventItemProxy.shouldBoost,
                             sender: eventItemProxy.sender,
                             content: buildTextTimelineItemContent(textMessageContent),
                             properties: .init(replyDetails: buildTimelineItemReplyDetails(messageLikeContent.inReplyTo),
                                               isThreaded: messageLikeContent.threadRoot != nil,
                                               threadSummary: buildTimelineItemThreadSummary(messageLikeContent.threadSummary),
                                               isEdited: messageContent.isEdited,
                                               reactions: buildAggregatedReactions(messageLikeContent.reactions),
                                               deliveryStatus: eventItemProxy.deliveryStatus,
                                               orderedReadReceipts: buildOrderedReadReceipts(eventItemProxy.readReceipts),
                                               encryptionAuthenticity: buildEncryptionAuthenticity(eventItemProxy.shieldState),
                                               encryptionForwarder: eventItemProxy.forwarder))
    }
    
    private func buildImageTimelineItem(for eventItemProxy: EventTimelineItemProxy,
                                        _ messageLikeContent: MsgLikeContent,
                                        _ messageContent: MessageContent,
                                        _ imageMessageContent: ImageMessageContent,
                                        _ isOutgoing: Bool) -> RoomTimelineItemProtocol {
        ImageRoomTimelineItem(id: eventItemProxy.id,
                              timestamp: eventItemProxy.timestamp,
                              isOutgoing: isOutgoing,
                              isEditable: eventItemProxy.isEditable,
                              canBeRepliedTo: eventItemProxy.canBeRepliedTo,
                              shouldBoost: eventItemProxy.shouldBoost,
                              sender: eventItemProxy.sender,
                              content: buildImageTimelineItemContent(imageMessageContent),
                              properties: .init(replyDetails: buildTimelineItemReplyDetails(messageLikeContent.inReplyTo),
                                                isThreaded: messageLikeContent.threadRoot != nil,
                                                threadSummary: buildTimelineItemThreadSummary(messageLikeContent.threadSummary),
                                                isEdited: messageContent.isEdited,
                                                reactions: buildAggregatedReactions(messageLikeContent.reactions),
                                                deliveryStatus: eventItemProxy.deliveryStatus,
                                                orderedReadReceipts: buildOrderedReadReceipts(eventItemProxy.readReceipts),
                                                encryptionAuthenticity: buildEncryptionAuthenticity(eventItemProxy.shieldState),
                                                encryptionForwarder: eventItemProxy.forwarder))
    }
    
    private func buildVideoTimelineItem(for eventItemProxy: EventTimelineItemProxy,
                                        _ messageLikeContent: MsgLikeContent,
                                        _ messageContent: MessageContent,
                                        _ videoMessageContent: VideoMessageContent,
                                        _ isOutgoing: Bool) -> RoomTimelineItemProtocol {
        VideoRoomTimelineItem(id: eventItemProxy.id,
                              timestamp: eventItemProxy.timestamp,
                              isOutgoing: isOutgoing,
                              isEditable: eventItemProxy.isEditable,
                              canBeRepliedTo: eventItemProxy.canBeRepliedTo,
                              shouldBoost: eventItemProxy.shouldBoost,
                              sender: eventItemProxy.sender,
                              content: buildVideoTimelineItemContent(videoMessageContent),
                              properties: .init(replyDetails: buildTimelineItemReplyDetails(messageLikeContent.inReplyTo),
                                                isThreaded: messageLikeContent.threadRoot != nil,
                                                threadSummary: buildTimelineItemThreadSummary(messageLikeContent.threadSummary),
                                                isEdited: messageContent.isEdited,
                                                reactions: buildAggregatedReactions(messageLikeContent.reactions),
                                                deliveryStatus: eventItemProxy.deliveryStatus,
                                                orderedReadReceipts: buildOrderedReadReceipts(eventItemProxy.readReceipts),
                                                encryptionAuthenticity: buildEncryptionAuthenticity(eventItemProxy.shieldState),
                                                encryptionForwarder: eventItemProxy.forwarder))
    }
    
    private func buildAudioTimelineItem(for eventItemProxy: EventTimelineItemProxy,
                                        _ messageLikeContent: MsgLikeContent,
                                        _ messageContent: MessageContent,
                                        _ audioMessageContent: AudioMessageContent,
                                        _ isOutgoing: Bool) -> RoomTimelineItemProtocol {
        AudioRoomTimelineItem(id: eventItemProxy.id,
                              timestamp: eventItemProxy.timestamp,
                              isOutgoing: isOutgoing,
                              isEditable: eventItemProxy.isEditable,
                              canBeRepliedTo: eventItemProxy.canBeRepliedTo,
                              shouldBoost: eventItemProxy.shouldBoost,
                              sender: eventItemProxy.sender,
                              content: buildAudioTimelineItemContent(audioMessageContent),
                              properties: .init(replyDetails: buildTimelineItemReplyDetails(messageLikeContent.inReplyTo),
                                                isThreaded: messageLikeContent.threadRoot != nil,
                                                threadSummary: buildTimelineItemThreadSummary(messageLikeContent.threadSummary),
                                                isEdited: messageContent.isEdited,
                                                reactions: buildAggregatedReactions(messageLikeContent.reactions),
                                                deliveryStatus: eventItemProxy.deliveryStatus,
                                                orderedReadReceipts: buildOrderedReadReceipts(eventItemProxy.readReceipts),
                                                encryptionAuthenticity: buildEncryptionAuthenticity(eventItemProxy.shieldState),
                                                encryptionForwarder: eventItemProxy.forwarder))
    }
    
    private func buildVoiceTimelineItem(for eventItemProxy: EventTimelineItemProxy,
                                        _ messageLikeContent: MsgLikeContent,
                                        _ messageContent: MessageContent,
                                        _ audioMessageContent: AudioMessageContent,
                                        _ isOutgoing: Bool) -> RoomTimelineItemProtocol {
        VoiceMessageRoomTimelineItem(id: eventItemProxy.id,
                                     timestamp: eventItemProxy.timestamp,
                                     isOutgoing: isOutgoing,
                                     isEditable: eventItemProxy.isEditable,
                                     canBeRepliedTo: eventItemProxy.canBeRepliedTo,
                                     sender: eventItemProxy.sender,
                                     content: buildAudioTimelineItemContent(audioMessageContent),
                                     properties: .init(replyDetails: buildTimelineItemReplyDetails(messageLikeContent.inReplyTo),
                                                       isThreaded: messageLikeContent.threadRoot != nil,
                                                       threadSummary: buildTimelineItemThreadSummary(messageLikeContent.threadSummary),
                                                       isEdited: messageContent.isEdited,
                                                       reactions: buildAggregatedReactions(messageLikeContent.reactions),
                                                       deliveryStatus: eventItemProxy.deliveryStatus,
                                                       orderedReadReceipts: buildOrderedReadReceipts(eventItemProxy.readReceipts),
                                                       encryptionAuthenticity: buildEncryptionAuthenticity(eventItemProxy.shieldState),
                                                       encryptionForwarder: eventItemProxy.forwarder))
    }
    
    private func buildFileTimelineItem(for eventItemProxy: EventTimelineItemProxy,
                                       _ messageLikeContent: MsgLikeContent,
                                       _ messageContent: MessageContent,
                                       _ fileMessageContent: FileMessageContent,
                                       _ isOutgoing: Bool) -> RoomTimelineItemProtocol {
        FileRoomTimelineItem(id: eventItemProxy.id,
                             timestamp: eventItemProxy.timestamp,
                             isOutgoing: isOutgoing,
                             isEditable: eventItemProxy.isEditable,
                             canBeRepliedTo: eventItemProxy.canBeRepliedTo,
                             shouldBoost: eventItemProxy.shouldBoost,
                             sender: eventItemProxy.sender,
                             content: buildFileTimelineItemContent(fileMessageContent),
                             properties: .init(replyDetails: buildTimelineItemReplyDetails(messageLikeContent.inReplyTo),
                                               isThreaded: messageLikeContent.threadRoot != nil,
                                               threadSummary: buildTimelineItemThreadSummary(messageLikeContent.threadSummary),
                                               isEdited: messageContent.isEdited,
                                               reactions: buildAggregatedReactions(messageLikeContent.reactions),
                                               deliveryStatus: eventItemProxy.deliveryStatus,
                                               orderedReadReceipts: buildOrderedReadReceipts(eventItemProxy.readReceipts),
                                               encryptionAuthenticity: buildEncryptionAuthenticity(eventItemProxy.shieldState),
                                               encryptionForwarder: eventItemProxy.forwarder))
    }
    
    private func buildNoticeTimelineItem(for eventItemProxy: EventTimelineItemProxy,
                                         _ messageLikeContent: MsgLikeContent,
                                         _ messageContent: MessageContent,
                                         _ noticeMessageContent: NoticeMessageContent,
                                         _ isOutgoing: Bool) -> RoomTimelineItemProtocol {
        NoticeRoomTimelineItem(id: eventItemProxy.id,
                               timestamp: eventItemProxy.timestamp,
                               isOutgoing: isOutgoing,
                               isEditable: eventItemProxy.isEditable,
                               canBeRepliedTo: eventItemProxy.canBeRepliedTo,
                               sender: eventItemProxy.sender,
                               content: buildNoticeTimelineItemContent(noticeMessageContent),
                               properties: .init(replyDetails: buildTimelineItemReplyDetails(messageLikeContent.inReplyTo),
                                                 isThreaded: messageLikeContent.threadRoot != nil,
                                                 threadSummary: buildTimelineItemThreadSummary(messageLikeContent.threadSummary),
                                                 isEdited: messageContent.isEdited,
                                                 reactions: buildAggregatedReactions(messageLikeContent.reactions),
                                                 deliveryStatus: eventItemProxy.deliveryStatus,
                                                 orderedReadReceipts: buildOrderedReadReceipts(eventItemProxy.readReceipts),
                                                 encryptionAuthenticity: buildEncryptionAuthenticity(eventItemProxy.shieldState),
                                                 encryptionForwarder: eventItemProxy.forwarder))
    }
    
    private func buildEmoteTimelineItem(for eventItemProxy: EventTimelineItemProxy,
                                        _ messageLikeContent: MsgLikeContent,
                                        _ messageContent: MessageContent,
                                        _ emoteMessageContent: EmoteMessageContent,
                                        _ isOutgoing: Bool) -> RoomTimelineItemProtocol {
        EmoteRoomTimelineItem(id: eventItemProxy.id,
                              timestamp: eventItemProxy.timestamp,
                              isOutgoing: isOutgoing,
                              isEditable: eventItemProxy.isEditable,
                              canBeRepliedTo: eventItemProxy.canBeRepliedTo,
                              sender: eventItemProxy.sender,
                              content: buildEmoteTimelineItemContent(senderDisplayName: eventItemProxy.sender.displayName, senderID: eventItemProxy.sender.id, messageContent: emoteMessageContent),
                              properties: .init(replyDetails: buildTimelineItemReplyDetails(messageLikeContent.inReplyTo),
                                                isThreaded: messageLikeContent.threadRoot != nil,
                                                threadSummary: buildTimelineItemThreadSummary(messageLikeContent.threadSummary),
                                                isEdited: messageContent.isEdited,
                                                reactions: buildAggregatedReactions(messageLikeContent.reactions),
                                                deliveryStatus: eventItemProxy.deliveryStatus,
                                                orderedReadReceipts: buildOrderedReadReceipts(eventItemProxy.readReceipts),
                                                encryptionAuthenticity: buildEncryptionAuthenticity(eventItemProxy.shieldState),
                                                encryptionForwarder: eventItemProxy.forwarder))
    }
    
    private func buildLocationTimelineItem(for eventItemProxy: EventTimelineItemProxy,
                                           _ messageLikeContent: MsgLikeContent,
                                           _ messageContent: MessageContent,
                                           _ locationMessageContent: LocationContent,
                                           _ isOutgoing: Bool) -> RoomTimelineItemProtocol {
        LocationRoomTimelineItem(id: eventItemProxy.id,
                                 timestamp: eventItemProxy.timestamp,
                                 isOutgoing: isOutgoing,
                                 isEditable: eventItemProxy.isEditable,
                                 canBeRepliedTo: eventItemProxy.canBeRepliedTo,
                                 sender: eventItemProxy.sender,
                                 content: buildLocationTimelineItemContent(locationMessageContent),
                                 properties: .init(replyDetails: buildTimelineItemReplyDetails(messageLikeContent.inReplyTo),
                                                   isThreaded: messageLikeContent.threadRoot != nil,
                                                   threadSummary: buildTimelineItemThreadSummary(messageLikeContent.threadSummary),
                                                   isEdited: messageContent.isEdited,
                                                   reactions: buildAggregatedReactions(messageLikeContent.reactions),
                                                   deliveryStatus: eventItemProxy.deliveryStatus,
                                                   orderedReadReceipts: buildOrderedReadReceipts(eventItemProxy.readReceipts),
                                                   encryptionAuthenticity: buildEncryptionAuthenticity(eventItemProxy.shieldState),
                                                   encryptionForwarder: eventItemProxy.forwarder))
    }
    
    private func buildGalleryTimelineItem(for eventItemProxy: EventTimelineItemProxy,
                                          _ messageLikeContent: MsgLikeContent,
                                          _ messageContent: MessageContent,
                                          _ galleryMessageContent: GalleryMessageContent,
                                          _ isOutgoing: Bool) -> RoomTimelineItemProtocol {
        TextRoomTimelineItem(id: eventItemProxy.id,
                             timestamp: eventItemProxy.timestamp,
                             isOutgoing: isOutgoing,
                             isEditable: eventItemProxy.isEditable,
                             canBeRepliedTo: eventItemProxy.canBeRepliedTo,
                             shouldBoost: eventItemProxy.shouldBoost,
                             sender: eventItemProxy.sender,
                             content: .init(body: galleryMessageContent.body),
                             properties: .init(replyDetails: buildTimelineItemReplyDetails(messageLikeContent.inReplyTo),
                                               isThreaded: messageLikeContent.threadRoot != nil,
                                               threadSummary: buildTimelineItemThreadSummary(messageLikeContent.threadSummary),
                                               isEdited: messageContent.isEdited,
                                               reactions: buildAggregatedReactions(messageLikeContent.reactions),
                                               deliveryStatus: eventItemProxy.deliveryStatus,
                                               orderedReadReceipts: buildOrderedReadReceipts(eventItemProxy.readReceipts),
                                               encryptionAuthenticity: buildEncryptionAuthenticity(eventItemProxy.shieldState),
                                               encryptionForwarder: eventItemProxy.forwarder))
    }
    
    private func buildStickerTimelineItem(_ eventItemProxy: EventTimelineItemProxy,
                                          _ messageLikeContent: MsgLikeContent,
                                          _ body: String,
                                          _ info: MatrixRustSDK.ImageInfo,
                                          _ mediaSource: MediaSource,
                                          _ isOutgoing: Bool) -> RoomTimelineItemProtocol {
        let imageInfo = ImageInfoProxy(source: mediaSource, width: info.width, height: info.height, mimeType: info.mimetype, fileSize: info.size.map(UInt.init))
        
        return StickerRoomTimelineItem(id: eventItemProxy.id,
                                       body: body,
                                       timestamp: eventItemProxy.timestamp,
                                       isOutgoing: isOutgoing,
                                       isEditable: eventItemProxy.isEditable,
                                       canBeRepliedTo: eventItemProxy.canBeRepliedTo,
                                       sender: eventItemProxy.sender,
                                       imageInfo: imageInfo,
                                       blurhash: info.blurhash,
                                       properties: .init(replyDetails: buildTimelineItemReplyDetails(messageLikeContent.inReplyTo),
                                                         isThreaded: messageLikeContent.threadRoot != nil,
                                                         threadSummary: buildTimelineItemThreadSummary(messageLikeContent.threadSummary),
                                                         reactions: buildAggregatedReactions(messageLikeContent.reactions),
                                                         deliveryStatus: eventItemProxy.deliveryStatus,
                                                         orderedReadReceipts: buildOrderedReadReceipts(eventItemProxy.readReceipts),
                                                         encryptionAuthenticity: buildEncryptionAuthenticity(eventItemProxy.shieldState),
                                                         encryptionForwarder: eventItemProxy.forwarder))
    }
    
    private func buildPollTimelineItem(_ eventItemProxy: EventTimelineItemProxy,
                                       _ messageLikeContent: MsgLikeContent,
                                       _ question: String,
                                       _ pollKind: PollKind,
                                       _ maxSelections: UInt64,
                                       _ answers: [PollAnswer],
                                       _ votes: [String: [String]],
                                       _ endTime: UInt64?,
                                       _ isOutgoing: Bool,
                                       _ edited: Bool) -> RoomTimelineItemProtocol {
        let allVotes = votes.reduce(0) { count, pair in
            count + pair.value.count
        }

        let maxOptionVotes = votes.map(\.value.count).max()

        let options = answers.map { answer in
            let optionVotesCount = votes[answer.id]?.count
            
            return Poll.Option(id: answer.id,
                               text: answer.text,
                               votes: optionVotesCount ?? 0,
                               allVotes: allVotes,
                               isSelected: votes[answer.id]?.contains(userID) ?? false,
                               isWinning: optionVotesCount.map { $0 == maxOptionVotes } ?? false)
        }
        
        let pollKind: Poll.Kind = switch pollKind {
        case .disclosed:
            .disclosed
        case .undisclosed:
            .undisclosed
        }

        let poll = Poll(question: question,
                        kind: pollKind,
                        maxSelections: Int(maxSelections),
                        options: options,
                        votes: votes,
                        endDate: endTime.map { Date(timeIntervalSince1970: TimeInterval($0 / 1000)) },
                        createdByAccountOwner: eventItemProxy.sender.id == userID)

        return PollRoomTimelineItem(id: eventItemProxy.id,
                                    poll: poll,
                                    body: poll.question,
                                    timestamp: eventItemProxy.timestamp,
                                    isOutgoing: isOutgoing,
                                    isEditable: eventItemProxy.isEditable,
                                    canBeRepliedTo: eventItemProxy.canBeRepliedTo,
                                    sender: eventItemProxy.sender,
                                    properties: .init(replyDetails: buildTimelineItemReplyDetails(messageLikeContent.inReplyTo),
                                                      isThreaded: messageLikeContent.threadRoot != nil,
                                                      threadSummary: buildTimelineItemThreadSummary(messageLikeContent.threadSummary),
                                                      isEdited: edited,
                                                      reactions: buildAggregatedReactions(messageLikeContent.reactions),
                                                      deliveryStatus: eventItemProxy.deliveryStatus,
                                                      orderedReadReceipts: buildOrderedReadReceipts(eventItemProxy.readReceipts),
                                                      encryptionAuthenticity: buildEncryptionAuthenticity(eventItemProxy.shieldState),
                                                      encryptionForwarder: eventItemProxy.forwarder))
    }
    
    private func buildRedactedTimelineItem(_ eventItemProxy: EventTimelineItemProxy,
                                           _ messageLikeContent: MsgLikeContent,
                                           _ isOutgoing: Bool) -> RoomTimelineItemProtocol {
        RedactedRoomTimelineItem(id: eventItemProxy.id,
                                 body: L10n.commonMessageRemoved,
                                 timestamp: eventItemProxy.timestamp,
                                 isOutgoing: isOutgoing,
                                 isEditable: eventItemProxy.isEditable,
                                 canBeRepliedTo: eventItemProxy.canBeRepliedTo,
                                 sender: eventItemProxy.sender,
                                 properties: .init(replyDetails: buildTimelineItemReplyDetails(messageLikeContent.inReplyTo),
                                                   isThreaded: messageLikeContent.threadRoot != nil,
                                                   threadSummary: buildTimelineItemThreadSummary(messageLikeContent.threadSummary)))
    }
    
    private func buildEncryptedTimelineItem(_ eventItemProxy: EventTimelineItemProxy,
                                            _ messageLikeContent: MsgLikeContent,
                                            _ encryptedMessage: EncryptedMessage,
                                            _ isOutgoing: Bool) -> RoomTimelineItemProtocol {
        var encryptionType = EncryptedRoomTimelineItem.EncryptionType.unknown
        var errorLabel = L10n.commonWaitingForDecryptionKey
        switch encryptedMessage {
        case .megolmV1AesSha2(let sessionID, let cause):
            switch cause {
            case .unknown:
                encryptionType = .megolmV1AesSha2(sessionID: sessionID, cause: .unknown)
                errorLabel = L10n.commonWaitingForDecryptionKey
            case .verificationViolation:
                encryptionType = .megolmV1AesSha2(sessionID: sessionID, cause: .verificationViolation)
                errorLabel = L10n.commonUnableToDecryptVerificationViolation
            case .unsignedDevice, .unknownDevice:
                encryptionType = .megolmV1AesSha2(sessionID: sessionID, cause: .insecureDevice)
                errorLabel = L10n.commonUnableToDecryptInsecureDevice
            case .sentBeforeWeJoined:
                encryptionType = .megolmV1AesSha2(sessionID: sessionID, cause: .sentBeforeWeJoined)
                errorLabel = L10n.commonUnableToDecryptNoAccess
            case .historicalMessageAndBackupIsDisabled:
                encryptionType = .megolmV1AesSha2(sessionID: sessionID, cause: .historicalMessageAndBackupDisabled)
                errorLabel = L10n.timelineDecryptionFailureHistoricalEventNoKeyBackup
            case .historicalMessageAndDeviceIsUnverified:
                encryptionType = .megolmV1AesSha2(sessionID: sessionID, cause: .historicalMessageAndDeviceIsUnverified)
                errorLabel = L10n.timelineDecryptionFailureHistoricalEventUnverifiedDevice
            case .withheldForUnverifiedOrInsecureDevice:
                encryptionType = .megolmV1AesSha2(sessionID: sessionID, cause: .withheldForUnverifiedOrInsecureDevice)
                errorLabel = L10n.timelineDecryptionFailureWithheldUnverified
            case .withheldBySender:
                encryptionType = .megolmV1AesSha2(sessionID: sessionID, cause: .witheldBySender)
                errorLabel = L10n.timelineDecryptionFailureUnableToDecrypt
            }
        case .olmV1Curve25519AesSha2(let senderKey):
            encryptionType = .olmV1Curve25519AesSha2(senderKey: senderKey)
        case .unknown:
            break
        }
        
        return EncryptedRoomTimelineItem(id: eventItemProxy.id,
                                         body: errorLabel,
                                         encryptionType: encryptionType,
                                         timestamp: eventItemProxy.timestamp,
                                         isOutgoing: isOutgoing,
                                         isEditable: eventItemProxy.isEditable,
                                         canBeRepliedTo: eventItemProxy.canBeRepliedTo,
                                         sender: eventItemProxy.sender,
                                         properties: .init(replyDetails: buildTimelineItemReplyDetails(messageLikeContent.inReplyTo),
                                                           isThreaded: messageLikeContent.threadRoot != nil,
                                                           threadSummary: buildTimelineItemThreadSummary(messageLikeContent.threadSummary)))
    }
    
    // MARK: - Message events content
    
    private func buildTextTimelineItemContent(_ messageContent: TextMessageContent) -> TextRoomTimelineItemContent {
        let htmlBody = messageContent.formatted?.format == .html ? messageContent.formatted?.body : nil
        let formattedBody = (htmlBody != nil ? attributedStringBuilder.fromHTML(htmlBody) : attributedStringBuilder.fromPlain(messageContent.body))
        
        return .init(body: messageContent.body, formattedBody: formattedBody, formattedBodyHTMLString: htmlBody)
    }
    
    private func buildAudioTimelineItemContent(_ messageContent: AudioMessageContent) -> AudioRoomTimelineItemContent {
        let htmlCaption = messageContent.formattedCaption?.format == .html ? messageContent.formattedCaption?.body : nil
        let formattedCaption = htmlCaption != nil ? attributedStringBuilder.fromHTML(htmlCaption) : attributedStringBuilder.fromPlain(messageContent.caption)
        
        var waveform: EstimatedWaveform?
        if let audioWaveform = messageContent.audio?.waveform {
            waveform = EstimatedWaveform(data: audioWaveform)
        }

        return AudioRoomTimelineItemContent(filename: messageContent.filename,
                                            caption: messageContent.caption,
                                            formattedCaption: formattedCaption,
                                            formattedCaptionHTMLString: htmlCaption,
                                            duration: messageContent.audio?.duration ?? 0,
                                            waveform: waveform,
                                            source: MediaSourceProxy(source: messageContent.source, mimeType: messageContent.info?.mimetype),
                                            fileSize: messageContent.info?.size.map(UInt.init),
                                            contentType: UTType(mimeType: messageContent.info?.mimetype, fallbackFilename: messageContent.filename))
    }
    
    private func buildImageTimelineItemContent(_ messageContent: ImageMessageContent) -> ImageRoomTimelineItemContent {
        let htmlCaption = messageContent.formattedCaption?.format == .html ? messageContent.formattedCaption?.body : nil
        let formattedCaption = htmlCaption != nil ? attributedStringBuilder.fromHTML(htmlCaption) : attributedStringBuilder.fromPlain(messageContent.caption)
        
        let thumbnailInfo = ImageInfoProxy(source: messageContent.info?.thumbnailSource,
                                           width: messageContent.info?.thumbnailInfo?.width,
                                           height: messageContent.info?.thumbnailInfo?.height,
                                           mimeType: messageContent.info?.thumbnailInfo?.mimetype,
                                           fileSize: messageContent.info?.size.map(UInt.init))
        
        let imageInfo = ImageInfoProxy(source: messageContent.source,
                                       width: messageContent.info?.width,
                                       height: messageContent.info?.height,
                                       mimeType: messageContent.info?.mimetype,
                                       fileSize: messageContent.info?.size.map(UInt.init))
        
        return .init(filename: messageContent.filename,
                     caption: messageContent.caption,
                     formattedCaption: formattedCaption,
                     formattedCaptionHTMLString: htmlCaption,
                     imageInfo: imageInfo,
                     thumbnailInfo: thumbnailInfo,
                     blurhash: messageContent.info?.blurhash,
                     contentType: UTType(mimeType: messageContent.info?.mimetype, fallbackFilename: messageContent.filename))
    }
    
    private func buildVideoTimelineItemContent(_ messageContent: VideoMessageContent) -> VideoRoomTimelineItemContent {
        let htmlCaption = messageContent.formattedCaption?.format == .html ? messageContent.formattedCaption?.body : nil
        let formattedCaption = htmlCaption != nil ? attributedStringBuilder.fromHTML(htmlCaption) : attributedStringBuilder.fromPlain(messageContent.caption)
        
        let thumbnailInfo = ImageInfoProxy(source: messageContent.info?.thumbnailSource,
                                           width: messageContent.info?.thumbnailInfo?.width,
                                           height: messageContent.info?.thumbnailInfo?.height,
                                           mimeType: messageContent.info?.thumbnailInfo?.mimetype,
                                           fileSize: messageContent.info?.size.map(UInt.init))
        
        let videoInfo = VideoInfoProxy(source: messageContent.source,
                                       duration: messageContent.info?.duration ?? 0,
                                       width: messageContent.info?.width,
                                       height: messageContent.info?.height,
                                       mimeType: messageContent.info?.mimetype,
                                       fileSize: messageContent.info?.size.map(UInt.init))
        
        return .init(filename: messageContent.filename,
                     caption: messageContent.caption,
                     formattedCaption: formattedCaption,
                     formattedCaptionHTMLString: htmlCaption,
                     videoInfo: videoInfo,
                     thumbnailInfo: thumbnailInfo,
                     blurhash: messageContent.info?.blurhash,
                     contentType: UTType(mimeType: messageContent.info?.mimetype, fallbackFilename: messageContent.filename))
    }

    private func buildLocationTimelineItemContent(_ locationContent: LocationContent) -> LocationRoomTimelineItemContent {
        LocationRoomTimelineItemContent(body: locationContent.body,
                                        geoURI: .init(string: locationContent.geoUri),
                                        description: locationContent.description)
    }

    private func buildFileTimelineItemContent(_ messageContent: FileMessageContent) -> FileRoomTimelineItemContent {
        let htmlCaption = messageContent.formattedCaption?.format == .html ? messageContent.formattedCaption?.body : nil
        let formattedCaption = htmlCaption != nil ? attributedStringBuilder.fromHTML(htmlCaption) : attributedStringBuilder.fromPlain(messageContent.caption)
        
        let thumbnailSource = messageContent.info?.thumbnailSource.map { MediaSourceProxy(source: $0, mimeType: messageContent.info?.thumbnailInfo?.mimetype) }
        
        return .init(filename: messageContent.filename,
                     caption: messageContent.caption,
                     formattedCaption: formattedCaption,
                     formattedCaptionHTMLString: htmlCaption,
                     source: MediaSourceProxy(source: messageContent.source, mimeType: messageContent.info?.mimetype),
                     fileSize: messageContent.info?.size.map(UInt.init),
                     thumbnailSource: thumbnailSource,
                     contentType: UTType(mimeType: messageContent.info?.mimetype, fallbackFilename: messageContent.filename))
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
            formattedBody = buildEmoteFormattedBodyFromHTML(html: htmlBody, name: name)
        } else {
            formattedBody = attributedStringBuilder.fromPlain(L10n.commonEmote(name, messageContent.body))
        }
        
        return .init(body: messageContent.body, formattedBody: formattedBody, formattedBodyHTMLString: htmlBody)
    }
    
    /// This fixes the issue of the name not belonging to the first <p> defined paragraph
    private func buildEmoteFormattedBodyFromHTML(html: String, name: String) -> AttributedString? {
        let htmlBodyPlaceholder = "{htmlBodyPlaceholder}"
        var finalString = AttributedString(L10n.commonEmote(name, htmlBodyPlaceholder))
        guard let htmlBodyString = attributedStringBuilder.fromHTML(html) else {
            return nil
        }
        finalString.replace(htmlBodyPlaceholder, with: htmlBodyString)
        return finalString
    }
    
    // MARK: - EventBasedTimelineItem Properties
    
    private func buildAggregatedReactions(_ reactions: [Reaction]) -> [AggregatedReaction] {
        reactions.map { reaction in
            let senders = reaction.senders
                .map { senderData in
                    ReactionSender(id: senderData.senderId, timestamp: Date(timeIntervalSince1970: TimeInterval(senderData.timestamp / 1000)))
                }
                .sorted { a, b in
                    // Sort reactions within an aggregation by timestamp descending.
                    // This puts the most recent at the top, useful in cases like the
                    // reaction summary view.
                    a.timestamp > b.timestamp
                }
            return AggregatedReaction(accountOwnerID: userID, key: reaction.key, senders: senders)
        }
        .sorted { a, b in
            // Sort aggregated reactions by count and then timestamp ascending, using
            // the most recent reaction in the aggregation(hence index 0).
            // This appends new aggregations on the end of the reaction layout
            // and the deterministic sort avoids reactions jumping around if the reactions timeline
            // view reloads.
            if a.count == b.count {
                return a.senders[0].timestamp < b.senders[0].timestamp
            }
            return a.count > b.count
        }
    }

    private func buildOrderedReadReceipts(_ receipts: [String: Receipt]) -> [ReadReceipt] {
        receipts
            .sorted { firstElement, secondElement in
                // If there is no timestamp we order them as last
                let firstTimestamp = firstElement.value.dateTimestamp ?? Date(timeIntervalSince1970: 0)
                let secondTimestamp = secondElement.value.dateTimestamp ?? Date(timeIntervalSince1970: 0)
                return firstTimestamp > secondTimestamp
            }
            .map { key, receipt in
                ReadReceipt(userID: key, formattedTimestamp: receipt.dateTimestamp?.formattedMinimal())
            }
    }
    
    private func buildEncryptionAuthenticity(_ shieldState: ShieldState?) -> EncryptionAuthenticity? {
        shieldState.flatMap(EncryptionAuthenticity.init)
    }
    
    private func buildTimelineItemThreadSummary(_ threadSummary: MatrixRustSDK.ThreadSummary?) -> TimelineItemThreadSummary? {
        guard let threadSummary else { return nil }
        
        switch threadSummary.latestEvent() {
        case .unavailable:
            return .notLoaded
        case .pending:
            return .loading
        case .ready(let content, let senderID, let senderProfile, _, _):
            let sender = TimelineItemSender(senderID: senderID, senderProfile: senderProfile)
            
            let latestEventContent: TimelineEventContent = switch content {
            case .msgLike(let messageLikeContent):
                switch messageLikeContent.kind {
                case .message(let messageContent):
                    .message(buildMessageTimelineItemContent(messageType: messageContent.msgType,
                                                             senderID: senderID,
                                                             senderDisplayName: sender.displayName))
                case .poll(let question, _, _, _, _, _, _):
                    .poll(question: question)
                case .sticker(let body, _, _):
                    .message(.text(.init(body: body)))
                case .redacted:
                    .redacted
                default:
                    .message(.text(.init(body: L10n.commonUnsupportedEvent)))
                }
            default:
                .message(.text(.init(body: L10n.commonUnsupportedEvent)))
            }
            
            return .loaded(senderID: senderID,
                           sender: sender,
                           latestEventContent: latestEventContent,
                           numberOfReplies: Int(threadSummary.numReplies()))
            
        case .error(let message):
            return .error(message: message)
        }
    }
    
    // MARK: - Other Events
    
    private func buildUnsupportedTimelineItem(_ eventItemProxy: EventTimelineItemProxy,
                                              _ eventType: String,
                                              _ error: String,
                                              _ isOutgoing: Bool) -> RoomTimelineItemProtocol {
        UnsupportedRoomTimelineItem(id: eventItemProxy.id,
                                    body: L10n.commonUnsupportedEvent,
                                    eventType: eventType,
                                    error: error,
                                    timestamp: eventItemProxy.timestamp,
                                    isOutgoing: isOutgoing,
                                    isEditable: eventItemProxy.isEditable,
                                    canBeRepliedTo: eventItemProxy.canBeRepliedTo,
                                    sender: eventItemProxy.sender,
                                    properties: .init())
    }
    
    private func buildCallInviteTimelineItem(for eventItemProxy: EventTimelineItemProxy) -> RoomTimelineItemProtocol {
        CallInviteRoomTimelineItem(id: eventItemProxy.id,
                                   timestamp: eventItemProxy.timestamp,
                                   isEditable: eventItemProxy.isEditable,
                                   canBeRepliedTo: eventItemProxy.canBeRepliedTo,
                                   sender: eventItemProxy.sender)
    }
    
    private func buildCallNotificationTimelineItem(for eventItemProxy: EventTimelineItemProxy) -> RoomTimelineItemProtocol {
        CallNotificationRoomTimelineItem(id: eventItemProxy.id,
                                         timestamp: eventItemProxy.timestamp,
                                         isEditable: eventItemProxy.isEditable,
                                         canBeRepliedTo: eventItemProxy.canBeRepliedTo,
                                         sender: eventItemProxy.sender)
    }
    
    // MARK: - State Events
    
    private func buildStateTimelineItem(for eventItemProxy: EventTimelineItemProxy,
                                        state: OtherState,
                                        isOutgoing: Bool) -> RoomTimelineItemProtocol? {
        guard let text = stateEventStringBuilder.buildString(for: state, sender: eventItemProxy.sender, isOutgoing: isOutgoing) else { return nil }
        return buildStateTimelineItem(for: eventItemProxy, text: text, isOutgoing: isOutgoing)
    }
    
    private func buildStateMembershipChangeTimelineItem(for eventItemProxy: EventTimelineItemProxy,
                                                        memberUserID: String,
                                                        memberDisplayName: String?,
                                                        membershipChange: MembershipChange?,
                                                        reason: String?,
                                                        isOutgoing: Bool) -> RoomTimelineItemProtocol? {
        guard let text = stateEventStringBuilder.buildString(for: membershipChange,
                                                             reason: reason,
                                                             memberUserID: memberUserID,
                                                             memberDisplayName: memberDisplayName,
                                                             sender: eventItemProxy.sender,
                                                             isOutgoing: isOutgoing) else {
            return nil
        }
        
        return buildStateTimelineItem(for: eventItemProxy, text: text, isOutgoing: isOutgoing)
    }
    
    private func buildStateProfileChangeTimelineItem(for eventItemProxy: EventTimelineItemProxy,
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
        return buildStateTimelineItem(for: eventItemProxy, text: text, isOutgoing: isOutgoing)
    }
    
    private func buildStateTimelineItem(for eventItemProxy: EventTimelineItemProxy, text: String, isOutgoing: Bool) -> RoomTimelineItemProtocol {
        StateRoomTimelineItem(id: eventItemProxy.id,
                              body: text,
                              timestamp: eventItemProxy.timestamp,
                              isOutgoing: isOutgoing,
                              isEditable: false,
                              canBeRepliedTo: eventItemProxy.canBeRepliedTo,
                              sender: eventItemProxy.sender)
    }
    
    // MARK: - Reply details
    
    private func buildTimelineItemReplyDetails(_ details: MatrixRustSDK.InReplyToDetails?) -> TimelineItemReplyDetails? {
        guard let details else {
            return nil
        }
        
        return buildTimelineItemReply(details).details
    }
    
    func buildTimelineItemReply(_ details: MatrixRustSDK.InReplyToDetails) -> TimelineItemReply {
        let isThreaded = details.event().isThreaded
        switch details.event() {
        case .unavailable:
            return .init(details: .notLoaded(eventID: details.eventId()), isThreaded: isThreaded)
        case .pending:
            return .init(details: .loading(eventID: details.eventId()), isThreaded: isThreaded)
        case let .ready(timelineItem, senderID, senderProfile, _, _):
            let sender = TimelineItemSender(senderID: senderID, senderProfile: senderProfile)
            
            let replyContent: TimelineEventContent
            
            switch timelineItem {
            case .msgLike(let messageLikeContent):
                switch messageLikeContent.kind {
                case .message(let messageContent):
                    let replyContent = buildMessageTimelineItemContent(messageType: messageContent.msgType,
                                                                       senderID: sender.id,
                                                                       senderDisplayName: sender.displayName)
                    return .init(details: .loaded(sender: sender,
                                                  eventID: details.eventId(),
                                                  eventContent: .message(replyContent)),
                                 isThreaded: isThreaded)
                case .poll(let question, _, _, _, _, _, _):
                    replyContent = .poll(question: question)
                case .sticker(let body, _, _):
                    replyContent = .message(.text(.init(body: body)))
                case .redacted:
                    replyContent = .redacted
                default:
                    replyContent = .message(.text(.init(body: L10n.commonUnsupportedEvent)))
                }
            default:
                replyContent = .message(.text(.init(body: L10n.commonUnsupportedEvent)))
            }
            
            return .init(details: .loaded(sender: sender, eventID: details.eventId(), eventContent: replyContent), isThreaded: isThreaded)
        case let .error(message):
            return .init(details: .error(eventID: details.eventId(), message: message), isThreaded: isThreaded)
        }
    }
    
    // MARK: - Helpers
    
    private func buildMessageTimelineItemContent(messageType: MessageType?, senderID: String, senderDisplayName: String?) -> EventBasedMessageTimelineItemContentType {
        switch messageType {
        case .audio(let content):
            if content.voice != nil {
                .voice(buildAudioTimelineItemContent(content))
            } else {
                .audio(buildAudioTimelineItemContent(content))
            }
        case .emote(let content):
            .emote(buildEmoteTimelineItemContent(senderDisplayName: senderDisplayName, senderID: senderID, messageContent: content))
        case .file(let content):
            .file(buildFileTimelineItemContent(content))
        case .image(let content):
            .image(buildImageTimelineItemContent(content))
        case .notice(let content):
            .notice(buildNoticeTimelineItemContent(content))
        case .text(let content):
            .text(buildTextTimelineItemContent(content))
        case .video(let content):
            .video(buildVideoTimelineItemContent(content))
        case .location(let content):
            .location(buildLocationTimelineItemContent(content))
        case .gallery(let content):
            .text(.init(body: content.body))
        case .other(_, let body):
            .text(.init(body: body))
        case .none:
            .text(.init(body: L10n.commonUnsupportedEvent))
        }
    }
}

private extension EmbeddedEventDetails {
    var isThreaded: Bool {
        switch self {
        case .ready(.msgLike(let messageLikeContent), _, _, _, _):
            return messageLikeContent.threadRoot != nil
        default:
            return false
        }
    }
}

private extension Receipt {
    var dateTimestamp: Date? {
        guard let timestamp else {
            return nil
        }
        return Date(timeIntervalSince1970: TimeInterval(timestamp / 1000))
    }
}

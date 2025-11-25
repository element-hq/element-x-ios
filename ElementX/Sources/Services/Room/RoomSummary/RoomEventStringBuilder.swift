//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRustSDK

struct RoomEventStringBuilder {
    let stateEventStringBuilder: RoomStateEventStringBuilder
    let messageEventStringBuilder: RoomMessageEventStringBuilder
    let shouldDisambiguateDisplayNames: Bool
    let shouldPrefixSenderName: Bool
    
    func buildAttributedString(for eventItemProxy: EventTimelineItemProxy) -> AttributedString? {
        buildAttributedString(for: eventItemProxy.content,
                              sender: eventItemProxy.sender,
                              isOutgoing: eventItemProxy.isOwn)
    }
    
    func buildAttributedString(for content: TimelineItemContent, sender: TimelineItemSender, isOutgoing: Bool) -> AttributedString? {
        let displayName = if shouldDisambiguateDisplayNames {
            sender.disambiguatedDisplayName ?? sender.id
        } else {
            sender.displayName ?? sender.id
        }
        
        switch content {
        case .msgLike(let messageLikeContent):
            switch messageLikeContent.kind {
            case .message(let messageContent):
                return messageEventStringBuilder.buildAttributedString(for: messageContent.msgType, senderDisplayName: displayName, isOutgoing: isOutgoing)
            case .sticker:
                if messageEventStringBuilder.destination == .pinnedEvent {
                    var string = AttributedString(L10n.commonSticker)
                    string.bold()
                    return string
                }
                return prefix(L10n.commonSticker, with: displayName, isOutgoing: isOutgoing)
            case .poll(let question, _, _, _, _, _, _):
                if messageEventStringBuilder.destination == .pinnedEvent {
                    let questionPlaceholder = "{question}"
                    var finalString = AttributedString(L10n.commonPollSummary(questionPlaceholder))
                    finalString.bold()
                    let normalString = AttributedString(question)
                    finalString.replace(questionPlaceholder, with: normalString)
                    return finalString
                }
                return prefix(L10n.commonPollSummary(question), with: displayName, isOutgoing: isOutgoing)
            case .redacted:
                return prefix(L10n.commonMessageRemoved, with: displayName, isOutgoing: isOutgoing)
            case .unableToDecrypt(let encryptedMessage):
                let errorMessage = switch encryptedMessage {
                case .megolmV1AesSha2(_, .sentBeforeWeJoined): L10n.commonUnableToDecryptNoAccess
                case .megolmV1AesSha2(_, .verificationViolation): L10n.commonUnableToDecryptVerificationViolation
                case .megolmV1AesSha2(_, .unknownDevice), .megolmV1AesSha2(_, .unsignedDevice): L10n.commonUnableToDecryptInsecureDevice
                default: L10n.commonWaitingForDecryptionKey
                }
                return prefix(errorMessage, with: displayName, isOutgoing: isOutgoing)
            case .other:
                return nil // We shouldn't receive these without asking for custom event types.
            }
        case .failedToParseMessageLike, .failedToParseState:
            return prefix(L10n.commonUnsupportedEvent, with: displayName, isOutgoing: isOutgoing)
        case .state(_, let state):
            return stateEventStringBuilder
                .buildString(for: state, sender: sender, isOutgoing: isOutgoing)
                .map(AttributedString.init)
        case .roomMembership(let userID, let displayName, let change, let reason):
            return stateEventStringBuilder
                .buildString(for: change, reason: reason, memberUserID: userID, memberDisplayName: displayName, sender: sender, isOutgoing: isOutgoing)
                .map(AttributedString.init)
        case .profileChange(let displayName, let prevDisplayName, let avatarUrl, let prevAvatarUrl):
            return stateEventStringBuilder
                .buildProfileChangeString(displayName: displayName,
                                          previousDisplayName: prevDisplayName,
                                          avatarURLString: avatarUrl,
                                          previousAvatarURLString: prevAvatarUrl,
                                          member: sender.id,
                                          memberIsYou: isOutgoing)
                .map(AttributedString.init)
        case .callInvite:
            return prefix(L10n.commonUnsupportedCall, with: displayName, isOutgoing: isOutgoing)
        case .rtcNotification:
            return prefix(L10n.commonCallStarted, with: displayName, isOutgoing: isOutgoing)
        }
    }
    
    private func prefix(_ eventSummary: String, with senderDisplayName: String, isOutgoing: Bool) -> AttributedString {
        guard shouldPrefixSenderName else {
            return AttributedString(eventSummary)
        }
        let attributedEventSummary = AttributedString(eventSummary.trimmingCharacters(in: .whitespacesAndNewlines))
        
        var attributedSenderDisplayName = AttributedString(isOutgoing ? L10n.commonYou : senderDisplayName)
        attributedSenderDisplayName.bold()
        
        // Don't include the message body in the markdown otherwise it makes tappable links.
        return attributedSenderDisplayName + ": " + attributedEventSummary
    }
    
    static func pinnedEventStringBuilder(userID: String) -> Self {
        RoomEventStringBuilder(stateEventStringBuilder: .init(userID: userID,
                                                              shouldDisambiguateDisplayNames: false),
                               messageEventStringBuilder: .init(attributedStringBuilder: AttributedStringBuilder(cacheKey: "pinnedEvents", mentionBuilder: PlainMentionBuilder()),
                                                                destination: .pinnedEvent),
                               shouldDisambiguateDisplayNames: false,
                               shouldPrefixSenderName: false)
    }
}

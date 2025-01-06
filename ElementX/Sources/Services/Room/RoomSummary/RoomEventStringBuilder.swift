//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
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
        let sender = eventItemProxy.sender
        let isOutgoing = eventItemProxy.isOwn
        let displayName = if shouldDisambiguateDisplayNames {
            sender.disambiguatedDisplayName ?? sender.id
        } else {
            sender.displayName ?? sender.id
        }
        
        switch eventItemProxy.content {
        case .unableToDecrypt(let encryptedMessage):
            let errorMessage = switch encryptedMessage {
            case .megolmV1AesSha2(_, .sentBeforeWeJoined): L10n.commonUnableToDecryptNoAccess
            case .megolmV1AesSha2(_, .verificationViolation): L10n.commonUnableToDecryptVerificationViolation
            case .megolmV1AesSha2(_, .unknownDevice), .megolmV1AesSha2(_, .unsignedDevice): L10n.commonUnableToDecryptInsecureDevice
            default: L10n.commonWaitingForDecryptionKey
            }
            return prefix(errorMessage, with: displayName)
        case .redactedMessage:
            return prefix(L10n.commonMessageRemoved, with: displayName)
        case .sticker:
            if messageEventStringBuilder.destination == .pinnedEvent {
                var string = AttributedString(L10n.commonSticker)
                string.bold()
                return string
            }
            return prefix(L10n.commonSticker, with: displayName)
        case .failedToParseMessageLike, .failedToParseState:
            return prefix(L10n.commonUnsupportedEvent, with: displayName)
        case .message(let messageContent):
            return messageEventStringBuilder.buildAttributedString(for: messageContent.msgType, senderDisplayName: displayName)
        case .state(_, let state):
            return stateEventStringBuilder
                .buildString(for: state, sender: sender, isOutgoing: isOutgoing)
                .map(AttributedString.init)
        case .roomMembership(let userID, let displayName, let change, _):
            return stateEventStringBuilder
                .buildString(for: change, memberUserID: userID, memberDisplayName: displayName, sender: sender, isOutgoing: isOutgoing)
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
        case .poll(let question, _, _, _, _, _, _):
            if messageEventStringBuilder.destination == .pinnedEvent {
                let questionPlaceholder = "{question}"
                var finalString = AttributedString(L10n.commonPollSummary(questionPlaceholder))
                finalString.bold()
                let normalString = AttributedString(question)
                finalString.replace(questionPlaceholder, with: normalString)
                return finalString
            }
            return prefix(L10n.commonPollSummary(question), with: displayName)
        case .callInvite:
            return prefix(L10n.commonUnsupportedCall, with: displayName)
        case .callNotify:
            return prefix(L10n.commonCallStarted, with: displayName)
        }
    }
    
    private func prefix(_ eventSummary: String, with senderDisplayName: String) -> AttributedString {
        guard shouldPrefixSenderName else {
            return AttributedString(eventSummary)
        }
        let attributedEventSummary = AttributedString(eventSummary.trimmingCharacters(in: .whitespacesAndNewlines))
        
        var attributedSenderDisplayName = AttributedString(senderDisplayName)
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

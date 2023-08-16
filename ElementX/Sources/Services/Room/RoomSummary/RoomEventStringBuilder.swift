//
// Copyright 2023 New Vector Ltd
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
import MatrixRustSDK

struct RoomEventStringBuilder {
    private let stateEventStringBuilder: RoomStateEventStringBuilder
    
    init(stateEventStringBuilder: RoomStateEventStringBuilder) {
        self.stateEventStringBuilder = stateEventStringBuilder
    }
    
    func buildAttributedString(for eventItemProxy: EventTimelineItemProxy) -> AttributedString? {
        let sender = eventItemProxy.sender
        let isOutgoing = eventItemProxy.isOwn
        
        switch eventItemProxy.content.kind() {
        case .unableToDecrypt:
            return prefix(L10n.commonDecryptionError, with: sender)
        case .redactedMessage:
            return prefix(L10n.commonMessageRemoved, with: sender)
        case .sticker:
            return prefix(L10n.commonSticker, with: sender)
        case .failedToParseMessageLike, .failedToParseState:
            return prefix(L10n.commonUnsupportedEvent, with: sender)
        case .message:
            guard let messageContent = eventItemProxy.content.asMessage() else {
                fatalError("Invalid message timeline item: \(eventItemProxy)")
            }
            
            guard let messageType = messageContent.msgtype() else {
                return prefix(messageContent.body(), with: sender)
            }
            
            let message: String
            switch messageType {
            // Message types that don't need a prefix.
            case .emote(content: let content):
                let senderDisplayName = sender.displayName ?? sender.id
                
                if let attributedMessage = attributedMessageFrom(formattedBody: content.formatted) {
                    return AttributedString(L10n.commonEmote(senderDisplayName, String(attributedMessage.characters)))
                } else {
                    return AttributedString(L10n.commonEmote(senderDisplayName, content.body))
                }
            // Message types that should be prefixed with the sender's name.
            case .audio:
                message = L10n.commonAudio
            case .image:
                message = L10n.commonImage
            case .video:
                message = L10n.commonVideo
            case .file:
                message = L10n.commonFile
            case .location:
                message = L10n.commonSharedLocation
            case .notice(content: let content):
                if let attributedMessage = attributedMessageFrom(formattedBody: content.formatted) {
                    message = String(attributedMessage.characters)
                } else {
                    message = content.body
                }
            case .text(content: let content):
                
                if let attributedMessage = attributedMessageFrom(formattedBody: content.formatted) {
                    message = String(attributedMessage.characters)
                } else {
                    message = content.body
                }
            }
            return prefix(message, with: sender)
        case .state(let stateKey, let state):
            return stateEventStringBuilder
                .buildString(for: state, stateKey: stateKey, sender: sender, isOutgoing: isOutgoing)
                .map(AttributedString.init)
        case .roomMembership(let userID, let change):
            return stateEventStringBuilder
                .buildString(for: change, member: userID, sender: sender, isOutgoing: isOutgoing)
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
        case .poll, .pollEnd:
            // The Rust SDK doesn't support poll events as room summaries yet
            return nil
        }
    }
    
    private func prefix(_ eventSummary: String, with sender: TimelineItemSender) -> AttributedString {
        let attributedEventSummary = AttributedString(eventSummary.trimmingCharacters(in: .whitespacesAndNewlines))
        
        if let senderDisplayName = sender.displayName {
            var attributedSenderDisplayName = AttributedString(senderDisplayName)
            attributedSenderDisplayName.bold()
            
            // Don't include the message body in the markdown otherwise it makes tappable links.
            return attributedSenderDisplayName + ": " + attributedEventSummary
        } else {
            return attributedEventSummary
        }
    }
    
    private func attributedMessageFrom(formattedBody: FormattedBody?) -> AttributedString? {
        formattedBody.flatMap { AttributedStringBuilder(permalinkBaseURL: .homeDirectory).fromHTML($0.body) }
    }
}

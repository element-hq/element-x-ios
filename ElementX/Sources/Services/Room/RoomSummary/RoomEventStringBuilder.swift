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

struct RoomEventStringBuilder {
    private let stateEventStringBuilder: RoomStateEventStringBuilder
    
    init(stateEventStringBuilder: RoomStateEventStringBuilder) {
        self.stateEventStringBuilder = stateEventStringBuilder
    }
    
    // swiftlint:disable:next cyclomatic_complexity
    func buildAttributedString(for eventItemProxy: EventTimelineItemProxy) -> AttributedString? {
        let sender = eventItemProxy.sender
        let isOutgoing = eventItemProxy.isOwn
        
        switch eventItemProxy.content.kind() {
        case .unableToDecrypt:
            return prefix(ElementL10n.encryptionInformationDecryptionError, with: sender)
        case .redactedMessage:
            return prefix(ElementL10n.eventRedacted, with: sender)
        case .sticker:
            return prefix(ElementL10n.sendASticker, with: sender)
        case .failedToParseMessageLike, .failedToParseState:
            return prefix(ElementL10n.roomTimelineItemUnsupported, with: sender)
        case .message:
            guard let messageContent = eventItemProxy.content.asMessage() else { fatalError("Invalid message timeline item: \(eventItemProxy)") }
            
            let message: String
            switch messageContent.msgtype() {
            // Message types that don't need a prefix.
            case .emote(content: let content):
                let senderDisplayName = sender.displayName ?? sender.id
                return AttributedString("* \(senderDisplayName) \(content.body)")
            // Message types that should be prefixed with the sender's name.
            case .image:
                message = ElementL10n.sentAnImage
            case .video:
                message = ElementL10n.sentAVideo
            case .file:
                message = ElementL10n.sentAFile
            default:
                message = messageContent.body()
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
        }
    }
    
    func prefix(_ eventSummary: String, with sender: TimelineItemSender) -> AttributedString {
        if let senderDisplayName = sender.displayName,
           let attributedSenderDisplayName = try? AttributedString(markdown: "**\(senderDisplayName)**") {
            // Don't include the message body in the markdown otherwise it makes tappable links.
            return attributedSenderDisplayName + ": " + AttributedString(eventSummary)
        } else {
            return AttributedString(eventSummary)
        }
    }
}

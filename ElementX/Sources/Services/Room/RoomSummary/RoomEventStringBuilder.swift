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
    private let messageEventStringBuilder: RoomMessageEventStringBuilder
    
    init(stateEventStringBuilder: RoomStateEventStringBuilder, messageEventStringBuilder: RoomMessageEventStringBuilder) {
        self.stateEventStringBuilder = stateEventStringBuilder
        self.messageEventStringBuilder = messageEventStringBuilder
    }
    
    func buildAttributedString(for eventItemProxy: EventTimelineItemProxy) -> AttributedString? {
        let sender = eventItemProxy.sender
        let isOutgoing = eventItemProxy.isOwn
        
        let senderDisplayName = sender.displayName ?? sender.id
        
        switch eventItemProxy.content.kind() {
        case .unableToDecrypt:
            return prefix(L10n.commonDecryptionError, with: senderDisplayName)
        case .redactedMessage:
            return prefix(L10n.commonMessageRemoved, with: senderDisplayName)
        case .sticker:
            return prefix(L10n.commonSticker, with: senderDisplayName)
        case .failedToParseMessageLike, .failedToParseState:
            return prefix(L10n.commonUnsupportedEvent, with: senderDisplayName)
        case .message:
            guard let messageContent = eventItemProxy.content.asMessage() else {
                fatalError("Invalid message timeline item: \(eventItemProxy)")
            }
            
            let messageType = messageContent.msgtype()
            return messageEventStringBuilder.buildAttributedString(for: messageType, senderDisplayName: senderDisplayName, prefixWithSenderName: true)
        case .state(_, let state):
            return stateEventStringBuilder
                .buildString(for: state, sender: sender, isOutgoing: isOutgoing)
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
        case .poll(let question, _, _, _, _, _, _):
            return prefix(L10n.commonPollSummary(question), with: senderDisplayName)
        }
    }
    
    private func prefix(_ eventSummary: String, with senderDisplayName: String) -> AttributedString {
        let attributedEventSummary = AttributedString(eventSummary.trimmingCharacters(in: .whitespacesAndNewlines))
        
        var attributedSenderDisplayName = AttributedString(senderDisplayName)
        attributedSenderDisplayName.bold()
        
        // Don't include the message body in the markdown otherwise it makes tappable links.
        return attributedSenderDisplayName + ": " + attributedEventSummary
    }
}

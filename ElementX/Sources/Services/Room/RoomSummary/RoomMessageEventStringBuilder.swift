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

struct RoomMessageEventStringBuilder {
    let attributedStringBuilder: AttributedStringBuilderProtocol
    
    func buildAttributedString(for messageType: MessageType, senderDisplayName: String, prefixWithSenderName: Bool) -> AttributedString {
        let message: String
        switch messageType {
        // Message types that don't need a prefix.
        case .emote(content: let content):
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
        
        if prefixWithSenderName {
            return prefix(message, with: senderDisplayName)
        } else {
            return AttributedString(message)
        }
    }
    
    private func prefix(_ eventSummary: String, with senderDisplayName: String) -> AttributedString {
        let attributedEventSummary = AttributedString(eventSummary.trimmingCharacters(in: .whitespacesAndNewlines))
        
        var attributedSenderDisplayName = AttributedString(senderDisplayName)
        attributedSenderDisplayName.bold()
        
        // Don't include the message body in the markdown otherwise it makes tappable links.
        return attributedSenderDisplayName + ": " + attributedEventSummary
    }
    
    private func attributedMessageFrom(formattedBody: FormattedBody?) -> AttributedString? {
        formattedBody.flatMap { attributedStringBuilder.fromHTML($0.body) }
    }
}

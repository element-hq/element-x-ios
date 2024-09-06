//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation
import MatrixRustSDK

struct RoomMessageEventStringBuilder {
    enum Prefix {
        case senderName
        case messageType
        case none
    }
    
    let attributedStringBuilder: AttributedStringBuilderProtocol
    let prefix: Prefix
    
    func buildAttributedString(for messageType: MessageType, senderDisplayName: String) -> AttributedString {
        let message: AttributedString
        switch messageType {
        // Message types that don't need a prefix.
        case .emote(content: let content):
            if let attributedMessage = attributedMessageFrom(formattedBody: content.formatted) {
                return AttributedString(L10n.commonEmote(senderDisplayName, String(attributedMessage.characters)))
            } else {
                return AttributedString(L10n.commonEmote(senderDisplayName, content.body))
            }
        // Message types that should be prefixed with the sender's name.
        case .audio(content: let content):
            let isVoiceMessage = content.voice != nil
            var content = AttributedString(isVoiceMessage ? L10n.commonVoiceMessage : L10n.commonAudio)
            if prefix == .messageType {
                content.bold()
            }
            message = content
        case .image(let content):
            message = prefix == .messageType ? prefix(AttributedString(content.body), with: L10n.commonImage) : AttributedString("\(L10n.commonImage) - \(content.body)")
        case .video(let content):
            message = prefix == .messageType ? prefix(AttributedString(content.body), with: L10n.commonVideo) : AttributedString("\(L10n.commonVideo) - \(content.body)")
        case .file(let content):
            message = prefix == .messageType ? prefix(AttributedString(content.body), with: L10n.commonFile) : AttributedString("\(L10n.commonFile) - \(content.body)")
        case .location:
            var content = AttributedString(L10n.commonSharedLocation)
            if prefix == .messageType {
                content.bold()
            }
            message = content
        case .notice(content: let content):
            if let attributedMessage = attributedMessageFrom(formattedBody: content.formatted) {
                message = attributedMessage
            } else {
                message = AttributedString(content.body)
            }
        case .text(content: let content):
            if let attributedMessage = attributedMessageFrom(formattedBody: content.formatted) {
                message = attributedMessage
            } else {
                message = AttributedString(content.body)
            }
        case .other(_, let body):
            message = AttributedString(body)
        }

        if prefix == .senderName {
            return prefix(message, with: senderDisplayName)
        } else {
            return message
        }
    }
    
    private func prefix(_ eventSummary: AttributedString, with textToBold: String) -> AttributedString {
        let attributedEventSummary = AttributedString(eventSummary.string.trimmingCharacters(in: .whitespacesAndNewlines))
        
        var attributedPrefix = AttributedString(textToBold + ":")
        attributedPrefix.bold()
        
        // Don't include the message body in the markdown otherwise it makes tappable links.
        return attributedPrefix + " " + attributedEventSummary
    }
    
    private func attributedMessageFrom(formattedBody: FormattedBody?) -> AttributedString? {
        formattedBody.flatMap { attributedStringBuilder.fromHTML($0.body) }
    }
}

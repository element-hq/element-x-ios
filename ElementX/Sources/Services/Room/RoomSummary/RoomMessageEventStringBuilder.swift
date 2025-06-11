//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRustSDK

struct RoomMessageEventStringBuilder {
    enum Destination {
        /// Strings show on the room list as the last message
        /// The sender will be prefixed in bold
        case roomList
        /// Events pinned to the banner on the top of the timeline
        /// The message type will be prefixed in bold
        case pinnedEvent
        /// Shown in push notifications
        /// No prefix
        case notification
    }

    let attributedStringBuilder: AttributedStringBuilderProtocol
    let destination: Destination
    
    func buildAttributedString(for messageType: MessageType, senderDisplayName: String, isOutgoing: Bool) -> AttributedString {
        let message: AttributedString
        switch messageType {
        case .emote(let content):
            if let attributedMessage = attributedMessageFrom(
                formattedBody: content.formatted) {
                return AttributedString(
                    L10n.commonEmote(senderDisplayName, String(attributedMessage.characters))
                )
            } else {
                return AttributedString(
                    L10n.commonEmote(senderDisplayName, content.body))
            }
        case .audio(let content):
            let isVoiceMessage = content.voice != nil
            var content = AttributedString(
                isVoiceMessage ? L10n.commonVoiceMessage : L10n.commonAudio)
            if destination == .pinnedEvent {
                content.bold()
            }
            message = content
        case .image(let content):
            message = buildMessage(for: destination, caption: content.caption,
                                   type: L10n.commonImage)
        case .video(let content):
            message = buildMessage(for: destination, caption: content.caption,
                                   type: L10n.commonVideo)
        case .file(let content):
            message = buildMessage(for: destination, caption: content.caption,
                                   type: L10n.commonFile)
        case .location:
            var content = AttributedString(L10n.commonSharedLocation)
            if destination == .pinnedEvent {
                content.bold()
            }
            message = content
        case .notice(let content):
            if let attributedMessage = attributedMessageFrom(
                formattedBody: content.formatted) {
                message = attributedMessage
            } else if let attributedMessage = attributedStringBuilder.fromPlain(
                content.body) {
                message = attributedMessage
            } else {
                message = AttributedString(content.body)
            }
        case .text(let content):
            let simplifiedPlainText = simplifyPlainText(plainText: content.body)
            if let attributedMessage = attributedMessageFrom(
                formattedBody: content.formatted) {
                message = attributedMessage
            } else if let attributedMessage = attributedStringBuilder.fromPlain(
                simplifiedPlainText) {
                message = attributedMessage
            } else {
                message = AttributedString(content.body)
            }
        case .gallery(let content):
            message = AttributedString(content.body)
        case .other(_, let body):
            message = AttributedString(body)
        }

        if destination == .roomList {
            return prefix(message, with: isOutgoing ? L10n.commonYou : senderDisplayName)
        } else {
            return message
        }
    }

    private func simplifyPlainText(plainText: String) -> String {
        let pattern = #"@\[(.+?)\]\(user:[0-9a-fA-F\-]+\)"#
        do {
            let regex = try NSRegularExpression(pattern: pattern)
            let newText = regex.stringByReplacingMatches(in: plainText,
                                                         range: NSRange(plainText.startIndex..., in: plainText),
                                                         withTemplate: "@$1")
            return newText
        } catch {
            return plainText
        }
    }

    private func buildMessage(for destination: Destination, caption: String?, type: String) -> AttributedString {
        guard let caption else {
            return AttributedString(type)
        }

        if destination == .pinnedEvent {
            return prefix(AttributedString(caption), with: type)
        } else {
            return AttributedString("\(type) - \(caption)")
        }
    }

    private func prefix(_ eventSummary: AttributedString, with textToBold: String) -> AttributedString {
        let attributedEventSummary = AttributedString(
            eventSummary.string.trimmingCharacters(in: .whitespacesAndNewlines))

        var attributedPrefix = AttributedString(textToBold + ":")
        attributedPrefix.bold()

        // Don't include the message body in the markdown otherwise it makes tappable links.
        return attributedPrefix + " " + attributedEventSummary
    }

    private func attributedMessageFrom(formattedBody: FormattedBody?)
        -> AttributedString? {
        formattedBody.flatMap { attributedStringBuilder.fromHTML($0.body) }
    }
}

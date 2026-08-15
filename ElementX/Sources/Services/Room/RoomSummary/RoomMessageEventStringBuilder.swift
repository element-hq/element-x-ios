//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRustSDK

nonisolated struct RoomMessageEventStringBuilder {
    enum Style {
        /// Plain: no prefix, no special text treatment
        /// Shown in push notifications and thread lists
        case plain
        /// Strings show on the room list as the last message
        /// The sender will be prefixed in bold
        case senderPrefixed
        /// Events pinned to the banner on the top of the timeline
        /// The message type will be prefixed in bold
        case typeBolded
    }
    
    let attributedStringBuilder: AttributedStringBuilderProtocol
    let style: Style
    
    func buildAttributedString(for messageType: MessageType, senderDisplayName: String, isOutgoing: Bool) -> AttributedString {
        let message: AttributedString
        switch messageType {
        case .emote(content: let content):
            if let attributedMessage = attributedMessageFrom(formattedBody: content.formatted) {
                return AttributedString(L10n.commonEmote(senderDisplayName, String(attributedMessage.characters)))
            } else {
                return AttributedString(L10n.commonEmote(senderDisplayName, content.body.strippingPlainTextReplyFallback()))
            }
        case .audio(content: let content):
            let isVoiceMessage = content.voice != nil
            var content = AttributedString(isVoiceMessage ? L10n.commonVoiceMessage : L10n.commonAudio)
            if style == .typeBolded {
                content.bold()
            }
            message = content
        case .image(let content):
            message = buildMessage(for: style, caption: content.caption, type: L10n.commonImage)
        case .video(let content):
            message = buildMessage(for: style, caption: content.caption, type: L10n.commonVideo)
        case .file(let content):
            message = buildMessage(for: style, caption: content.caption, type: L10n.commonFile)
        case .location:
            var content = AttributedString(L10n.commonSharedLocation)
            if style == .typeBolded {
                content.bold()
            }
            message = content
        case .notice(content: let content):
            if let attributedMessage = attributedMessageFrom(formattedBody: content.formatted) {
                message = attributedMessage
            } else {
                message = AttributedString(content.body.strippingPlainTextReplyFallback())
            }
        case .text(content: let content):
            if let attributedMessage = attributedMessageFrom(formattedBody: content.formatted) {
                message = attributedMessage
            } else {
                message = AttributedString(content.body.strippingPlainTextReplyFallback())
            }
        case .gallery(let content):
            message = buildGalleryMessage(for: style, content: content)
        case .other(_, let body):
            message = AttributedString(body)
        }
        
        if style == .senderPrefixed {
            return prefix(message, with: isOutgoing ? L10n.commonYou : senderDisplayName)
        } else {
            return message
        }
    }
    
    func buildAttributedStringForLiveLocation(senderDisplayName: String, isOutgoing: Bool) -> AttributedString {
        var message = AttributedString(L10n.commonSharedLiveLocation)
        if style == .typeBolded {
            message.bold()
        }
        
        if style == .senderPrefixed {
            return prefix(message, with: isOutgoing ? L10n.commonYou : senderDisplayName)
        } else {
            return message
        }
    }
    
    /// A gallery's body is its caption. Notifications fall back to counting the attachments when
    /// there isn't one, whilst elsewhere it is treated as any other media's caption.
    private func buildGalleryMessage(for style: Style, content: GalleryMessageContent) -> AttributedString {
        switch style {
        case .plain:
            if content.body.isBlank {
                AttributedString(L10n.notificationGalleryBody(content.itemtypes.count))
            } else {
                AttributedString(content.body)
            }
        case .senderPrefixed, .typeBolded:
            buildMessage(for: style, caption: content.body, type: L10n.commonGallery)
        }
    }
    
    private func buildMessage(for style: Style, caption: String?, type: String) -> AttributedString {
        guard let caption, !caption.isBlank else {
            return AttributedString(type)
        }
        
        if style == .typeBolded {
            return prefix(AttributedString(caption), with: type)
        } else {
            return AttributedString("\(type) - \(caption)")
        }
    }
    
    private func prefix(_ eventSummary: AttributedString, with textToBold: String) -> AttributedString {
        var attributedEventSummary = eventSummary.trimmingWhitespaceAndNewlines()
        // Previews aren't interactive; keep link text but drop the tappable attribute.
        attributedEventSummary.link = nil
        
        var attributedPrefix = AttributedString(textToBold + ":")
        attributedPrefix.bold()
        
        return attributedPrefix + " " + attributedEventSummary
    }
    
    private func attributedMessageFrom(formattedBody: FormattedBody?) -> AttributedString? {
        formattedBody.flatMap { attributedStringBuilder.fromHTML($0.body.strippingHTMLReplyFallback())?.flattenedForPreview() }
    }
}

private nonisolated extension String {
    /// Removes the rich reply fallback (`<mx-reply>...</mx-reply>`) from a
    /// formatted body: previews show the reply itself, not the quoted original.
    func strippingHTMLReplyFallback() -> String {
        guard let start = range(of: "<mx-reply>"),
              let end = range(of: "</mx-reply>"),
              start.lowerBound < end.upperBound else {
            return self
        }
        var result = self
        result.removeSubrange(start.lowerBound..<end.upperBound)
        return result
    }
    
    /// Removes the plain-text reply fallback: the leading `> <@user:server> ...`
    /// quoted lines up to the first blank line. Gated on the `> <` signature so
    /// a message genuinely starting with a markdown quote is left alone.
    func strippingPlainTextReplyFallback() -> String {
        guard hasPrefix("> <") else {
            return self
        }
        let lines = components(separatedBy: "\n")
        guard let blankIndex = lines.firstIndex(where: \.isEmpty), blankIndex + 1 < lines.count else {
            return self
        }
        return lines[(blankIndex + 1)...].joined(separator: "\n")
    }
}

//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import UIKit

nonisolated protocol EventBasedTimelineItemProtocol: RoomTimelineItemProtocol, CustomStringConvertible {
    var timestamp: Date { get }
    var isOutgoing: Bool { get }
    var isEditable: Bool { get }
    var canBeRepliedTo: Bool { get }
    
    var sender: TimelineItemSender { get }
    
    var body: String { get }
    
    var properties: RoomTimelineItemProperties { get }
}

nonisolated extension EventBasedTimelineItemProtocol {
    var description: String {
        "\(String(describing: Self.self)): id: \(id), timestamp: \(timestamp), isOutgoing: \(isOutgoing), properties: \(properties)"
    }
    
    var isForwardable: Bool {
        isRemoteMessage && !(self is PollRoomTimelineItem)
    }
    
    var isRemoteMessage: Bool {
        id.eventID != nil
    }
    
    var isRedacted: Bool {
        self is RedactedRoomTimelineItem
    }
    
    var pollIfAvailable: Poll? {
        (self as? PollRoomTimelineItem)?.poll
    }
    
    var hasStatusIcon: Bool {
        hasFailedToSend || properties.encryptionAuthenticity != nil || properties.encryptionForwarder != nil
    }
    
    var hasFailedToSend: Bool {
        properties.deliveryStatus?.isSendingFailed == true
    }
    
    var hasFailedDecryption: Bool {
        self is EncryptedRoomTimelineItem
    }
    
    var timelineMenuDescription: String {
        switch self {
        case is VoiceMessageRoomTimelineItem:
            return L10n.commonVoiceMessage
        default:
            return body.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
    
    /// The inline area to reserve at the trailing edge of the message text so the
    /// bubble's natural size accommodates the timestamp (which is overlaid on the
    /// bubble's bottom-trailing corner). Text wraps around this area: if it fits on
    /// the last line, the timestamp tucks inline; otherwise it sits on a new line.
    /// Sized using the same dynamic-type-aware font as the rendered timestamp.
    var trailingReservedSize: CGSize {
        let textStyle: UIFont.TextStyle = .caption1 // matches compound.bodyXS
        let font = UIFont.preferredFont(forTextStyle: textStyle)
        let textSize = (localizedSendInfo as NSString).size(withAttributes: [.font: font])
        var width = textSize.width
        var height = textSize.height
        if hasStatusIcon {
            // CompoundIcon at .xSmall is 16pt at the base size; scale with the same UIFontMetrics
            // as the icon's `relativeTo: .compound.bodyXS` modifier, plus the 4pt HStack spacing.
            let iconSize = UIFontMetrics(forTextStyle: textStyle).scaledValue(for: 16)
            width += iconSize + 4
            height = max(height, iconSize)
        }
        // Small visual gap between the text content and the overlaid timestamp.
        width += 4
        return CGSize(width: ceil(width), height: ceil(height))
    }
    
    /// contains the timestamp and an optional edited localised prefix
    /// example: (edited) 12:17 PM
    var localizedSendInfo: String {
        var start = ""
        if properties.isEdited {
            start = "\(L10n.commonEditedSuffix) "
        }
        return start + timestamp.formattedTime()
    }
    
    var isCopyable: Bool {
        guard let messageBasedItem = self as? EventBasedMessageTimelineItemProtocol else {
            return false
        }
        
        switch messageBasedItem.contentType {
        case .audio, .file, .image, .video, .location, .voice, .gallery:
            return false
        case .text, .emote, .notice:
            return true
        }
    }
    
    var supportsMediaCaption: Bool {
        guard let messageBasedItem = self as? EventBasedMessageTimelineItemProtocol else { return false }
        return messageBasedItem.supportsMediaCaption
    }
    
    var hasMediaCaption: Bool {
        guard let messageBasedItem = self as? EventBasedMessageTimelineItemProtocol else { return false }
        return messageBasedItem.hasMediaCaption
    }
}

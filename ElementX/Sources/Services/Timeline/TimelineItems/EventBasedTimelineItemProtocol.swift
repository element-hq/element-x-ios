//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation
import UIKit

protocol EventBasedTimelineItemProtocol: RoomTimelineItemProtocol, CustomStringConvertible {
    var timestamp: String { get }
    var isOutgoing: Bool { get }
    var isEditable: Bool { get }
    var canBeRepliedTo: Bool { get }
    
    var sender: TimelineItemSender { get }
    
    var body: String { get }
    
    var properties: RoomTimelineItemProperties { get }
}

extension EventBasedTimelineItemProtocol {
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
        hasFailedToSend || properties.encryptionAuthenticity != nil
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

    func additionalWhitespaces() -> Int {
        var whiteSpaces = 1
        localizedSendInfo.forEach { _ in
            whiteSpaces += 1
        }

        // To account for the extra spacing created by the status icon
        if hasStatusIcon {
            whiteSpaces += 3
        }

        return whiteSpaces
    }

    /// contains the timestamp and an optional edited localised prefix
    /// example: (edited) 12:17 PM
    var localizedSendInfo: String {
        var start = ""
        if properties.isEdited {
            start = "\(L10n.commonEditedSuffix) "
        }
        return start + timestamp
    }

    var isCopyable: Bool {
        guard let messageBasedItem = self as? EventBasedMessageTimelineItemProtocol else {
            return false
        }

        switch messageBasedItem.contentType {
        case .audio, .file, .image, .video, .location, .voice:
            return false
        case .text, .emote, .notice:
            return true
        }
    }
}

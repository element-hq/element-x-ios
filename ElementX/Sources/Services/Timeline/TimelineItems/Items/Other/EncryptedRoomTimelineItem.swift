//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import UIKit

struct EncryptedRoomTimelineItem: EventBasedTimelineItemProtocol, Equatable {
    enum EncryptionType: Hashable {
        case megolmV1AesSha2(sessionID: String, cause: UTDCause)
        case olmV1Curve25519AesSha2(senderKey: String)
        case unknown
    }
    
    enum UTDCause: Hashable {
        case sentBeforeWeJoined
        case verificationViolation
        case insecureDevice
        case unknown
        case historicalMessageAndBackupDisabled
        case historicalMessageAndDeviceIsUnverified
        case witheldBySender
        case withheldForUnverifiedOrInsecureDevice
    }
    
    let id: TimelineItemIdentifier
    let body: String
    let encryptionType: EncryptionType
    let timestamp: Date
    let isOutgoing: Bool
    let isEditable: Bool
    let canBeRepliedTo: Bool
    
    let sender: TimelineItemSender
    
    var properties = RoomTimelineItemProperties()
}

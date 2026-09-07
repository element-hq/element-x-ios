//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRtc

/// Turns an MSC4143 media-key to-device message into the record the core expects.
nonisolated enum EncryptionKeyMapper {
    /// - Returns: nil when the message is untrusted or unusable.
    static func map(_ message: MatrixRtcToDeviceMessage) -> FfiReceivedEncryptionKey? {
        // A cleartext to-device message has no attested sender: anyone could inject a media key.
        guard message.wasEncrypted else {
            MatrixRtcLog.warning("Dropping a cleartext encryption key")
            return nil
        }
        guard let senderDeviceID = message.senderDeviceID else {
            MatrixRtcLog.warning("Dropping an encryption key with no sender device")
            return nil
        }
        guard let data = message.contentJSON.data(using: .utf8),
              let content = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let roomID = content["room_id"] as? String,
              let memberID = content["member_id"] as? String,
              // `format` names the media_key encoding and is the core's to interpret; unknown ones still go through.
              let mediaKey = content["media_key"] as? [String: Any],
              let keyB64 = mediaKey["key"] as? String,
              let keyIndex = mediaKey["index"] as? Int, let index = UInt8(exactly: keyIndex) else {
            MatrixRtcLog.warning("Cannot parse encryption key content")
            return nil
        }
        
        return FfiReceivedEncryptionKey(roomId: roomID,
                                        memberId: memberID,
                                        keyB64: keyB64,
                                        keyIndex: index,
                                        wasEncrypted: true,
                                        senderUserId: message.attestedSenderID,
                                        senderDeviceId: senderDeviceID,
                                        senderIsCrossSigned: message.isSenderCrossSigned)
    }
}

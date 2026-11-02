//
// Copyright 2025 Element Creations Ltd.
// Copyright 2024-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// The incoming call a VoIP push carries from the NSE to the app.
nonisolated struct VoIPPushPayload {
    /// Internal rather than private so tests can build pushes with a field missing.
    enum Key: String {
        case roomID
        case roomDisplayName
        /// When an incoming call is set to ring, there will be a `m.rtc.notification`event  (MSC4075).
        /// Keep the notification event id as it is needed to decline calls (MSC4310).
        case rtcNotifyEventID
        /// The Date at which the incoming call should stop ringing.
        case expirationDate
        case isVoiceCall
        /// The user ID of the account the call is for.
        case receiverID
    }
    
    let roomID: String
    let roomDisplayName: String?
    let rtcNotificationID: String
    let receiverID: String
    let expirationDate: Date
    let isVoiceCall: Bool
    
    /// The payload the NSE hands to `CXProvider.reportNewIncomingVoIPPushPayload(_:)`.
    var dictionary: [String: Any] {
        var dictionary: [String: Any] = [Key.roomID.rawValue: roomID,
                                         Key.rtcNotifyEventID.rawValue: rtcNotificationID,
                                         Key.receiverID.rawValue: receiverID,
                                         Key.expirationDate.rawValue: expirationDate,
                                         Key.isVoiceCall.rawValue: isVoiceCall]
        dictionary[Key.roomDisplayName.rawValue] = roomDisplayName
        return dictionary
    }
    
    init(roomID: String, roomDisplayName: String?, rtcNotificationID: String, receiverID: String, expirationDate: Date, isVoiceCall: Bool) {
        self.roomID = roomID
        self.roomDisplayName = roomDisplayName
        self.rtcNotificationID = rtcNotificationID
        self.receiverID = receiverID
        self.expirationDate = expirationDate
        self.isVoiceCall = isVoiceCall
    }
    
    init?(dictionary: [AnyHashable: Any]) {
        guard let roomID = dictionary[Key.roomID.rawValue] as? String,
              let rtcNotificationID = dictionary[Key.rtcNotifyEventID.rawValue] as? String,
              let receiverID = dictionary[Key.receiverID.rawValue] as? String,
              let expirationDate = dictionary[Key.expirationDate.rawValue] as? Date else {
            return nil
        }
        
        self.init(roomID: roomID,
                  roomDisplayName: dictionary[Key.roomDisplayName.rawValue] as? String,
                  rtcNotificationID: rtcNotificationID,
                  receiverID: receiverID,
                  expirationDate: expirationDate,
                  isVoiceCall: dictionary[Key.isVoiceCall.rawValue] as? Bool ?? false)
    }
}

nonisolated let ElementCallServiceNotificationDiscardDelta = 15.0

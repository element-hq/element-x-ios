//
// Copyright 2025 Element Creations Ltd.
// Copyright 2024-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

enum ElementCallServiceNotificationKey: String {
    case roomID
    case roomDisplayName
    /// When an incoming call is set to ring, there will be a `m.rtc.notification`event  (MSC4075).
    /// Keep the notification event id as it is needed to decline calls (MSC4310).
    case rtcNotifyEventID
    /// The local timestamp in millis at which the incoming call should stop ringing.
    case expirationTimestampMillis
}

let ElementCallServiceNotificationDiscardDelta = 15.0

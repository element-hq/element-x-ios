//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import UserNotifications

nonisolated extension NotificationTone {
    /// A `UNNotificationSound` for this tone, ready to attach to a notification content object.
    var notificationSound: UNNotificationSound {
        UNNotificationSound(named: UNNotificationSoundName(NotificationToneManager.soundName(for: self)))
    }
}

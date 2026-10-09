//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import UserNotifications

nonisolated extension AccountSettings {
    /// The sound name to use in outgoing notifications.
    /// Falls back to the default Element X tone if no tone has been selected.
    var notificationSoundName: UNNotificationSoundName {
        if let selectedNotificationTone {
            UNNotificationSoundName(NotificationToneManager.soundName(for: selectedNotificationTone))
        } else {
            UNNotificationSoundName("message.caf")
        }
    }
    
    /// A `UNNotificationSound` built from `notificationSoundName`, ready to attach to a notification content object.
    var notificationSound: UNNotificationSound {
        UNNotificationSound(named: notificationSoundName)
    }
}

nonisolated extension AppSettings {
    var defaultNotificationSound: UNNotificationSound {
        UNNotificationSound(named: UNNotificationSoundName("message.caf"))
    }
}

//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import UserNotifications

extension CommonSettingsProtocol {
    /// The sound name to use in outgoing notifications.
    /// Falls back to the default Element X tone if no custom tone has been selected.
    var notificationSoundName: UNNotificationSoundName {
        if selectedNotificationTone == nil {
            return UNNotificationSoundName("message.caf")
        } else {
            return UNNotificationSoundName(NotificationToneManager.selectedToneFilename)
        }
    }

    /// A `UNNotificationSound` built from `notificationSoundName`, ready to attach to a notification content object.
    var notificationSound: UNNotificationSound {
        UNNotificationSound(named: notificationSoundName)
    }
}

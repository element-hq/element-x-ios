//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import UserNotifications

extension CommonSettingsProtocol {
    var notificationSoundName: UNNotificationSoundName {
        if selectedNotificationTone == nil {
            return UNNotificationSoundName("message.caf")
        } else {
            return UNNotificationSoundName(NotificationAlertTone.selectedToneFilename)
        }
    }

    var notificationSound: UNNotificationSound {
        UNNotificationSound(named: notificationSoundName)
    }
}

//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import UserNotifications

nonisolated extension AccountSettings {
    /// The sound to attach to outgoing notifications, falling back to the default tone if no tone has been selected.
    var notificationSound: UNNotificationSound {
        (selectedNotificationTone ?? defaultNotificationTone.publisher.value).notificationSound
    }
}

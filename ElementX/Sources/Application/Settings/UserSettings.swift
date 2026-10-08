//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import Macros

/// The settings for a signed in account, composed of the app wide settings and the settings
/// specific to that account.
final nonisolated class UserSettings: Sendable {
    let app: AppSettings
    let account: AccountSettings
    
    init(appSettings: AppSettings, accountSettings: AccountSettings) {
        app = appSettings
        account = accountSettings
    }
    
    static func mock(userID: String = "@me:matrix.org") -> UserSettings {
        AppSettings.volatile().userSettings(for: userID)
    }
}

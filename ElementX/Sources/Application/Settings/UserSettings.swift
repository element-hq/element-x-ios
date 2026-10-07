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
@dynamicMemberLookup
final nonisolated class UserSettings: Sendable {
    private let app: AppSettings
    private let account: AccountSettings
    
    init(appSettings: AppSettings, accountSettings: AccountSettings) {
        self.app = appSettings
        self.account = accountSettings
    }
    
    static func mock(userID: String = "@me:matrix.org") -> UserSettings {
        AppSettings.volatile().userSettings(for: userID)
    }
    
    subscript<Value>(dynamicMember keyPath: ReferenceWritableKeyPath<AppSettings, Value>) -> Value {
        get { app[keyPath: keyPath] }
        set { app[keyPath: keyPath] = newValue }
    }
    
    subscript<Value>(dynamicMember keyPath: KeyPath<AppSettings, Value>) -> Value {
        app[keyPath: keyPath]
    }
    
    subscript<Value>(dynamicMember keyPath: ReferenceWritableKeyPath<AccountSettings, Value>) -> Value {
        get { account[keyPath: keyPath] }
        set { account[keyPath: keyPath] = newValue }
    }
    
    subscript<Value>(dynamicMember keyPath: KeyPath<AccountSettings, Value>) -> Value {
        account[keyPath: keyPath]
    }
    
    func migrateAppSettingsValueToAccountSettings(_ keyPath: KeyPath<AccountSettings, UserPreferenceKey>) {
        account.migrateAppSettingsValue(keyPath)
    }
    
    func resetSessionSpecificSettings() {
        account.reset()
    }
}

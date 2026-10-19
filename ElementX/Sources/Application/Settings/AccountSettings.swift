//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation
import Macros

final nonisolated class AccountSettings: @unchecked Sendable {
    /// UserDefaults to be used on reads and writes.
    private let store: AccountUserDefaults
    private let userID: String
    
    // MARK: Session Activity
    
    /// When this account was last selected, used to order the accounts most recently selected first.
    @UserPreference
    var lastSelectedDate: Date?
    
    @UserPreference(defaultValue: false)
    var hasRunIdentityConfirmationOnboarding: Bool
    
    /// The queries the user searched for and the rooms they opened from the results, most recent first.
    @UserPreference(defaultValue: [SearchBreadcrumb]())
    var searchBreadcrumbs: [SearchBreadcrumb]
    
    /// The Set of room identifiers of invites that the user already saw in the invites list.
    /// This Set is being used to implement badges for unread invites.
    @UserPreference(defaultValue: Set<String>())
    var seenInvites: Set<String>
    
    /// The rooms this account is sharing its live location in.
    @UserPreference(key: "liveLocationSharingTimeoutDatesByRoomID", defaultValue: [String: LiveLocationSession]())
    var liveLocationSharingSessionsByRoomID: [String: LiveLocationSession]
    
    // MARK: Visible Preferences
    
    @UserPreference(defaultValue: true)
    var showAllRoomListActivity: Bool
    
    /// Whether this account's notifications are on. When off, its pusher is deleted from the homeserver.
    @UserPreference(defaultValue: true)
    var enableNotifications: Bool
    
    /// The tone played when the user hasn't selected one, which the homeserver can configure remotely.
    let defaultNotificationTone: RemotePreference<NotificationTone> = .init(.default)
    
    /// The sound played when delivering noisy notifications. If nil, use ``defaultNotificationTone``.
    @UserPreference
    var selectedNotificationTone: NotificationTone?
    
    @UserPreference(defaultValue: true)
    var sharePresence: Bool
    
    init(userID: String, store: UserDefaultsProtocol) {
        self.store = .init(userID: userID, store: store)
        self.userID = userID
    }
    
    func migrateAppSettingsValue(_ keyPath: KeyPath<AccountSettings, UserPreferenceKey>) {
        let storeKey = self[keyPath: keyPath].rawValue
        store.migrateAppSettingsValue(forKey: storeKey)
    }
    
    func reset() {
        MXLog.warning("Resetting AccountSettings for \(userID).")
        store.reset()
    }
}

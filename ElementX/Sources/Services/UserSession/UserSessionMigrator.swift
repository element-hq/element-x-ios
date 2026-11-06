//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI
import Version

// sourcery: AutoMockable
protocol UserSessionMigratorProtocol {
    /// Migrates a restored session to the new app version, unless it's already up to date.
    func migrate(_ userSession: UserSessionProtocol) async
    /// Marks a new account's session as up to date, as it has nothing to migrate.
    func markAsMigrated(_ userSession: UserSessionProtocol)
}

struct UserSessionMigrator: UserSessionMigratorProtocol {
    let newVersion: Version
    let oldAppVersion: Version?
    let appSettings: AppSettings
    let appMediator: AppMediatorProtocol
    
    // swiftlint:disable:next cyclomatic_complexity
    func migrate(_ userSession: UserSessionProtocol) async {
        // Before we start, we need to migrate lastVersionMigrated from the oldAppVersion.
        if userSession.userSettings.account.lastVersionMigrated == nil, let oldAppVersion, oldAppVersion < Version(26, 11, 2) {
            userSession.userSettings.account.lastVersionMigrated = oldAppVersion.description
        }
        
        guard let oldVersion = userSession.userSettings.account.lastVersionMigrated.flatMap(Version.init), oldVersion < newVersion else { return }
        
        MXLog.info("Migrating user session from \(oldVersion)")
        
        // Vacuuming can outlast a background task, getting the app killed before the migrations below run.
        if appMediator.appState != .background {
            MXLog.info("Performing client store optimizations.")
            await userSession.clientProxy.optimizeStores()
            MXLog.info("Finished optimizing client stores.")
        }
        
        if oldVersion < Version(1, 6, 0) {
            MXLog.info("Migrating to v1.6.0, marking identity confirmation onboarding as ran.")
            userSession.userSettings.account.hasRunIdentityConfirmationOnboarding = true
            userSession.userSettings.app.hasRunNotificationPermissionsOnboarding = true
        }
        
        if oldVersion < Version(25, 6, 0) {
            MXLog.info("Migrating to version 25.06.0, migrating timeline media settings to account data.")
            performSettingsToAccountDataMigration(userSession: userSession)
        }
        
        if oldVersion < Version(25, 9, 2) {
            MXLog.info("Migrating to version 25.09.2, triggering sync to ensure m.space state is up to date.")
            await userSession.clientProxy.expireSyncSessions()
        }
        
        if oldVersion < Version(25, 10, 0) {
            MXLog.info("Migrating to version 25.10.0, showing new sound banner to existing user.")
            appSettings.hasSeenNewSoundBanner = false
        }
        
        if oldVersion < Version(26, 07, 3) {
            MXLog.info("Migrating to version 26.07.3, marking the app as previously signed in.")
            appSettings.hasSignedInBefore = true
        }
        
        if oldVersion < Version(26, 10, 1) {
            MXLog.info("Migrating to version 26.10.1, moving initial 'session specific' settings.")
            userSession.userSettings.account.migrateAppSettingsValue(\.hasRunIdentityConfirmationOnboardingKey)
            userSession.userSettings.account.migrateAppSettingsValue(\.searchBreadcrumbsKey)
        }
        
        if oldVersion < Version(26, 10, 2) {
            MXLog.info("Migrating to version 26.10.2, moving visible account settings.")
            userSession.userSettings.account.migrateAppSettingsValue(\.showAllRoomListActivityKey)
            userSession.userSettings.account.migrateAppSettingsValue(\.selectedNotificationToneKey)
            userSession.userSettings.account.migrateAppSettingsValue(\.sharePresenceKey)
            
            // Make sure system notification sounds are available in the new directory.
            if let selectedNotificationTone = userSession.userSettings.account.selectedNotificationTone {
                do {
                    MXLog.info("Copying the selected system notification sound.")
                    try NotificationToneManager.copySystemToneIfNeeded(selectedNotificationTone)
                } catch {
                    MXLog.error("Failed migrating the selected notification sound: \(error)")
                }
            }
        }
        
        if oldVersion < Version(26, 10, 3) {
            MXLog.info("Migrating to version 26.10.3, moving the notifications switch into the account.")
            userSession.userSettings.account.migrateAppSettingsValue(\.enableNotificationsKey)
        }
        
        if oldVersion < Version(26, 10, 4) {
            MXLog.info("Migrating to version 26.10.4, moving the seen invites into the account.")
            userSession.userSettings.account.migrateAppSettingsValue(\.seenInvitesKey)
        }
        
        markAsMigrated(userSession)
    }
    
    func markAsMigrated(_ userSession: UserSessionProtocol) {
        userSession.userSettings.account.lastVersionMigrated = newVersion.description
    }
    
    // MARK: - Private
    
    /// This could be removed once the adoption of 25.06.x is widespread.
    private func performSettingsToAccountDataMigration(userSession: UserSessionProtocol) {
        guard let userDefaults = UserDefaults(suiteName: InfoPlistReader.main.appGroupIdentifier) else {
            return
        }
        
        let hideInviteAvatars = userDefaults.value(forKey: "hideInviteAvatars") as? Bool
        let timelineMediaVisibility = userDefaults
            .data(forKey: "timelineMediaVisibility")
            .flatMap {
                try? JSONDecoder().decode(TimelineMediaVisibility.self, from: $0)
            }
        let hideTimelineMedia = userDefaults.value(forKey: "hideTimelineMedia") as? Bool
        
        guard hideInviteAvatars != nil || timelineMediaVisibility != nil || hideTimelineMedia != nil else {
            // No migration needed, no local settings found.
            return
        }
        
        Task {
            switch await userSession.clientProxy.fetchMediaPreviewConfiguration() {
            case let .success(config):
                guard config == nil else {
                    // Found a server configuration, no need to migrate.
                    userDefaults.removeObject(forKey: "hideInviteAvatars")
                    userDefaults.removeObject(forKey: "timelineMediaVisibility")
                    userDefaults.removeObject(forKey: "hideTimelineMedia")
                    return
                }
                
                if let hideInviteAvatars, case .success = await userSession.clientProxy.setHideInviteAvatars(hideInviteAvatars) {
                    userDefaults.removeObject(forKey: "hideInviteAvatars")
                }
                
                if let timelineMediaVisibility, case .success = await userSession.clientProxy.setTimelineMediaVisibility(timelineMediaVisibility) {
                    userDefaults.removeObject(forKey: "timelineMediaVisibility")
                } else if let hideTimelineMedia, case .success = await userSession.clientProxy.setTimelineMediaVisibility(hideTimelineMedia ? .never : .always) {
                    userDefaults.removeObject(forKey: "hideTimelineMedia")
                }
            case let .failure(error):
                MXLog.error("Could not perform migration, failed to fetch media preview config: \(error)")
                return
            }
        }
    }
}

//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

nonisolated struct NotificationExtensionPresencePolicy: Sendable {
    static let foregroundActiveMaximumAge: TimeInterval = 30
    static let foregroundActiveRefreshInterval = foregroundActiveMaximumAge / 2
    
    let sharePresence: Bool
    let mainAppActivityStateSnapshot: MainAppActivityStateSnapshot
    
    init(sharePresence: Bool, mainAppActivityStateSnapshot: MainAppActivityStateSnapshot) {
        self.sharePresence = sharePresence
        self.mainAppActivityStateSnapshot = mainAppActivityStateSnapshot
    }
    
    init(appSettings: CommonSettingsProtocol, sharedPresenceStateStore: SharedPresenceStateStoreProtocol) {
        self.init(sharePresence: appSettings.sharePresence,
                  mainAppActivityStateSnapshot: sharedPresenceStateStore.mainAppActivityStateSnapshot)
    }
    
    func shouldForceOfflinePresence(currentSystemUptime: TimeInterval = ProcessInfo.processInfo.systemUptime) -> Bool {
        guard sharePresence else {
            return true
        }
        
        guard mainAppActivityStateSnapshot.state == .foregroundActive,
              let lastUpdatedSystemUptime = mainAppActivityStateSnapshot.lastUpdatedSystemUptime,
              currentSystemUptime >= lastUpdatedSystemUptime else {
            return true
        }
        
        return currentSystemUptime - lastUpdatedSystemUptime > Self.foregroundActiveMaximumAge
    }
    
    func performBeforeNotificationFetch<Output>(
        currentSystemUptime: TimeInterval = ProcessInfo.processInfo.systemUptime,
        forceOfflinePresence: () async throws -> Void,
        fetchNotification: () async throws -> Output
    ) async throws -> Output {
        if shouldForceOfflinePresence(currentSystemUptime: currentSystemUptime) {
            do {
                try await forceOfflinePresence()
            } catch {
                MXLog.error("Failed setting offline presence before notification processing with error: \(error)")
            }
        }
        
        return try await fetchNotification()
    }
}

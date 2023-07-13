//
// Copyright 2023 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Combine
import Foundation
import MatrixRustSDK

private final class WeakNotificationSettingsProxy: NotificationSettingsDelegate {
    private weak var proxy: NotificationSettingsProxy?
    
    init(proxy: NotificationSettingsProxy) {
        self.proxy = proxy
    }
    
    // MARK: - NotificationSettingsDelegate
    
    func settingsDidChange() {
        Task {
            await proxy?.settingsDidChange()
        }
    }
}

final class NotificationSettingsProxy: NotificationSettingsProxyProtocol {
    private(set) var notificationSettings: MatrixRustSDK.NotificationSettingsProtocol
    private let backgroundTaskService: BackgroundTaskServiceProtocol?

    let callbacks = PassthroughSubject<NotificationSettingsProxyCallback, Never>()

    init(notificationSettings: MatrixRustSDK.NotificationSettingsProtocol, backgroundTaskService: BackgroundTaskServiceProtocol?) {
        self.notificationSettings = notificationSettings
        self.backgroundTaskService = backgroundTaskService
        notificationSettings.setDelegate(delegate: WeakNotificationSettingsProxy(proxy: self))
    }
    
    func getNotificationSettings(roomId: String, isEncrypted: Bool, activeMembersCount: UInt64) async throws -> RoomNotificationSettingsProxyProtocol {
        let roomMotificationSettings = try await notificationSettings.getRoomNotificationSettings(roomId: roomId, isEncrypted: isEncrypted, activeMembersCount: activeMembersCount)
        return RoomNotificationSettingsProxy(roomNotificationSettings: roomMotificationSettings)
    }
    
    func setNotificationMode(roomId: String, mode: RoomNotificationMode) async throws {
        let backgroundTask = await backgroundTaskService?.startBackgroundTask(withName: "setNotificationMode")
        defer { backgroundTask?.stop() }
        
        try await notificationSettings.setRoomNotificationMode(roomId: roomId, mode: mode)
    }
    
    func getDefaultNotificationRoomMode(isEncrypted: Bool, activeMembersCount: UInt64) async -> RoomNotificationMode {
        await notificationSettings.getDefaultRoomNotificationMode(isEncrypted: isEncrypted, activeMembersCount: activeMembersCount)
    }
    
    func restoreDefaultNotificationMode(roomId: String) async throws {
        let backgroundTask = await backgroundTaskService?.startBackgroundTask(withName: "restoreDefaultNotificationMode")
        defer { backgroundTask?.stop() }

        try await notificationSettings.restoreDefaultRoomNotificationMode(roomId: roomId)
    }
    
    func containsKeywordsRules() async -> Bool {
        await notificationSettings.containsKeywordsRules()
    }
       
    func unmuteRoom(roomId: String, isEncrypted: Bool, activeMembersCount: UInt64) async throws {
        let backgroundTask = await backgroundTaskService?.startBackgroundTask(withName: "unmuteRoom")
        defer { backgroundTask?.stop() }

        try await notificationSettings.unmuteRoom(roomId: roomId, isEncrypted: isEncrypted, membersCount: activeMembersCount)
    }
    
    func isRoomMentionEnabled() async throws -> Bool {
        try await notificationSettings.isRoomMentionEnabled()
    }
    
    func setRoomMentionEnabled(enabled: Bool) async throws {
        let backgroundTask = await backgroundTaskService?.startBackgroundTask(withName: "setRoomMentionEnabled")
        defer { backgroundTask?.stop() }

        try await notificationSettings.setRoomMentionEnabled(enabled: enabled)
    }
    
    func isUserMentionEnabled() async throws -> Bool {
        try await notificationSettings.isUserMentionEnabled()
    }
    
    func setUserMentionEnabled(enabled: Bool) async throws {
        let backgroundTask = await backgroundTaskService?.startBackgroundTask(withName: "setUserMentionEnabled")
        defer { backgroundTask?.stop() }

        try await notificationSettings.setUserMentionEnabled(enabled: enabled)
    }
    
    func isCallEnabled() async throws -> Bool {
        try await notificationSettings.isCallEnabled()
    }
    
    func setCallEnabled(enabled: Bool) async throws {
        let backgroundTask = await backgroundTaskService?.startBackgroundTask(withName: "setCallEnabled")
        defer { backgroundTask?.stop() }

        try await notificationSettings.setCallEnabled(enabled: enabled)
    }
    
    // MARK: - Private
    
    @MainActor
    func settingsDidChange() {
        callbacks.send(.settingsDidChange)
    }
}

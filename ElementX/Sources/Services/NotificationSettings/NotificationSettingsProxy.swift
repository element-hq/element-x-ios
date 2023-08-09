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
    
    func getNotificationSettings(roomId: String, isEncrypted: Bool, isOneToOne: Bool) async throws -> RoomNotificationSettingsProxyProtocol {
        let roomMotificationSettings = try await notificationSettings.getRoomNotificationSettings(roomId: roomId, isEncrypted: isEncrypted, isOneToOne: isOneToOne)
        return RoomNotificationSettingsProxy(roomNotificationSettings: roomMotificationSettings)
    }
    
    func setNotificationMode(roomId: String, mode: RoomNotificationModeProxy) async throws {
        let backgroundTask = await backgroundTaskService?.startBackgroundTask(withName: "setNotificationMode")
        defer { backgroundTask?.stop() }
        
        try await notificationSettings.setRoomNotificationMode(roomId: roomId, mode: mode.roomNotificationMode)
        await updatedSettings()
    }
    
    func getUserDefinedRoomNotificationMode(roomId: String) async throws -> RoomNotificationModeProxy? {
        let roomNotificationMode = try await notificationSettings.getUserDefinedRoomNotificationMode(roomId: roomId)
        return roomNotificationMode.flatMap { RoomNotificationModeProxy.from(roomNotificationMode: $0) }
    }
    
    func getDefaultRoomNotificationMode(isEncrypted: Bool, isOneToOne: Bool) async -> RoomNotificationModeProxy {
        let roomNotificationMode = await notificationSettings.getDefaultRoomNotificationMode(isEncrypted: isEncrypted, isOneToOne: isOneToOne)
        return RoomNotificationModeProxy.from(roomNotificationMode: roomNotificationMode)
    }

    func setDefaultRoomNotificationMode(isEncrypted: Bool, isOneToOne: Bool, mode: RoomNotificationModeProxy) async throws {
        let backgroundTask = await backgroundTaskService?.startBackgroundTask(withName: "setDefaultRoomNotificationMode")
        defer { backgroundTask?.stop() }
        
        try await notificationSettings.setDefaultRoomNotificationMode(isEncrypted: isEncrypted, isOneToOne: isOneToOne, mode: mode.roomNotificationMode)
        await updatedSettings()
    }
    
    func restoreDefaultNotificationMode(roomId: String) async throws {
        let backgroundTask = await backgroundTaskService?.startBackgroundTask(withName: "restoreDefaultNotificationMode")
        defer { backgroundTask?.stop() }

        try await notificationSettings.restoreDefaultRoomNotificationMode(roomId: roomId)
        await updatedSettings()
    }
    
    func containsKeywordsRules() async -> Bool {
        await notificationSettings.containsKeywordsRules()
    }
       
    func unmuteRoom(roomId: String, isEncrypted: Bool, isOneToOne: Bool) async throws {
        let backgroundTask = await backgroundTaskService?.startBackgroundTask(withName: "unmuteRoom")
        defer { backgroundTask?.stop() }

        try await notificationSettings.unmuteRoom(roomId: roomId, isEncrypted: isEncrypted, isOneToOne: isOneToOne)
        await updatedSettings()
    }
    
    func isRoomMentionEnabled() async throws -> Bool {
        try await notificationSettings.isRoomMentionEnabled()
    }
    
    func setRoomMentionEnabled(enabled: Bool) async throws {
        let backgroundTask = await backgroundTaskService?.startBackgroundTask(withName: "setRoomMentionEnabled")
        defer { backgroundTask?.stop() }

        try await notificationSettings.setRoomMentionEnabled(enabled: enabled)
        await updatedSettings()
    }
    
    func isUserMentionEnabled() async throws -> Bool {
        try await notificationSettings.isUserMentionEnabled()
    }
    
    func setUserMentionEnabled(enabled: Bool) async throws {
        let backgroundTask = await backgroundTaskService?.startBackgroundTask(withName: "setUserMentionEnabled")
        defer { backgroundTask?.stop() }

        try await notificationSettings.setUserMentionEnabled(enabled: enabled)
        await updatedSettings()
    }
    
    func isCallEnabled() async throws -> Bool {
        try await notificationSettings.isCallEnabled()
    }
    
    func setCallEnabled(enabled: Bool) async throws {
        let backgroundTask = await backgroundTaskService?.startBackgroundTask(withName: "setCallEnabled")
        defer { backgroundTask?.stop() }

        try await notificationSettings.setCallEnabled(enabled: enabled)
        await updatedSettings()
    }
    
    func getRoomsWithUserDefinedRules() async throws -> [String] {
        await notificationSettings.getRoomsWithUserDefinedRules(enabled: true)
    }
    
    // MARK: - Private
    
    func updatedSettings() async {
        // The timeout avoids having to wait indefinitely. This can happen when setting a mode that is already the current mode,
        // as in this case no API call is made by the RustSDK and the push rules are therefore not updated.
        _ = await callbacks
            .timeout(.seconds(2.0), scheduler: DispatchQueue.main, options: nil, customError: nil)
            .values.first(where: { $0 == .settingsDidChange })
    }
    
    @MainActor
    func settingsDidChange() {
        callbacks.send(.settingsDidChange)
    }
}

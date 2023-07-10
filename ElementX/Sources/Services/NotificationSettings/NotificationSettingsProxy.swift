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
    private var syncUpdateCancellable: AnyCancellable?

    let callbacks = PassthroughSubject<NotificationSettingsProxyCallback, Never>()

    init(notificationSettingsProxy: MatrixRustSDK.NotificationSettingsProtocol) {
        notificationSettings = notificationSettingsProxy
        notificationSettings.setDelegate(delegate: WeakNotificationSettingsProxy(proxy: self))
    }
    
    func getNotificationSettings(room: RoomProxyProtocol) async throws -> RoomNotificationSettingsProxyProtocol {
        let roomMotificationSettings = try await notificationSettings.getRoomNotificationSettings(roomId: room.id, isEncrypted: room.isEncrypted, activeMembersCount: UInt64(room.activeMembersCount))
        return RoomNotificationSettingsProxy(roomNotificationSettings: roomMotificationSettings)
    }
    
    func setNotificationMode(room: RoomProxyProtocol, mode: RoomNotificationMode) async throws {
        try await notificationSettings.setRoomNotificationMode(roomId: room.id, mode: mode)
    }
    
    func getDefaultNotificationRoomMode(isEncrypted: Bool, activeMembersCount: UInt64) async -> RoomNotificationMode {
        await notificationSettings.getDefaultRoomNotificationMode(isEncrypted: isEncrypted, activeMembersCount: activeMembersCount)
    }
    
    func restoreDefaultNotificationMode(room: RoomProxyProtocol) async throws {
        try await notificationSettings.restoreDefaultRoomNotificationMode(roomId: room.id)
    }
    
    func containsKeywordsRules() async -> Bool {
        await notificationSettings.containsKeywordsRules()
    }
       
    func unmuteRoom(room: RoomProxyProtocol) async throws {
        try await notificationSettings.unmuteRoom(roomId: room.id, isEncrypted: room.isEncrypted, membersCount: UInt64(room.activeMembersCount))
    }
    
    func isRoomMentionEnabled() async throws -> Bool {
        try await notificationSettings.isRoomMentionEnabled()
    }
    
    func setRoomMentionEnabled(enabled: Bool) async throws {
        try await notificationSettings.setRoomMentionEnabled(enabled: enabled)
    }
    
    func isUserMentionEnabled() async throws -> Bool {
        try await notificationSettings.isUserMentionEnabled()
    }
    
    func setUserMentionEnabled(enabled: Bool) async throws {
        try await notificationSettings.setUserMentionEnabled(enabled: enabled)
    }
    
    func isCallEnabled() async throws -> Bool {
        try await notificationSettings.isCallEnabled()
    }
    
    func setCallEnabled(enabled: Bool) async throws {
        try await notificationSettings.setCallEnabled(enabled: enabled)
    }
    
    // MARK: - Private
    
    @MainActor
    func settingsDidChange() {
        callbacks.send(.settingsDidChange)
    }
}

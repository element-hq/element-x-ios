//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
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
    
    let callbacks = PassthroughSubject<NotificationSettingsProxyCallback, Never>()

    init(notificationSettings: MatrixRustSDK.NotificationSettingsProtocol) {
        self.notificationSettings = notificationSettings
        notificationSettings.setDelegate(delegate: WeakNotificationSettingsProxy(proxy: self))
    }
    
    func getNotificationSettings(roomId: String, isEncrypted: Bool, isOneToOne: Bool) async throws -> RoomNotificationSettingsProxyProtocol {
        let roomMotificationSettings = try await notificationSettings.getRoomNotificationSettings(roomId: roomId, isEncrypted: isEncrypted, isOneToOne: isOneToOne)
        return RoomNotificationSettingsProxy(roomNotificationSettings: roomMotificationSettings)
    }
    
    func setNotificationMode(roomId: String, mode: RoomNotificationModeProxy) async throws {
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
        do {
            try await notificationSettings.setDefaultRoomNotificationMode(isEncrypted: isEncrypted, isOneToOne: isOneToOne, mode: mode.roomNotificationMode)
        } catch NotificationSettingsError.RuleNotFound(let ruleId) {
            // `setDefaultRoomNotificationMode` updates multiple rules including unstable rules (e.g. the polls push rules defined in the MSC3930)
            // since production home servers may not have these rules yet, we drop the RuleNotFound error
            MXLog.warning("Unable to find the rule: \(ruleId)")
            return
        }

        await updatedSettings()
    }
    
    func restoreDefaultNotificationMode(roomId: String) async throws {
        try await notificationSettings.restoreDefaultRoomNotificationMode(roomId: roomId)
        await updatedSettings()
    }
       
    func unmuteRoom(roomId: String, isEncrypted: Bool, isOneToOne: Bool) async throws {
        try await notificationSettings.unmuteRoom(roomId: roomId, isEncrypted: isEncrypted, isOneToOne: isOneToOne)
        await updatedSettings()
    }
    
    func isRoomMentionEnabled() async throws -> Bool {
        try await notificationSettings.isRoomMentionEnabled()
    }
    
    func setRoomMentionEnabled(enabled: Bool) async throws {
        try await notificationSettings.setRoomMentionEnabled(enabled: enabled)
        await updatedSettings()
    }
    
    func isCallEnabled() async throws -> Bool {
        try await notificationSettings.isCallEnabled()
    }
    
    func setCallEnabled(enabled: Bool) async throws {
        try await notificationSettings.setCallEnabled(enabled: enabled)
        await updatedSettings()
    }
    
    func isInviteForMeEnabled() async throws -> Bool {
        try await notificationSettings.isInviteForMeEnabled()
    }
    
    func setInviteForMeEnabled(enabled: Bool) async throws {
        try await notificationSettings.setInviteForMeEnabled(enabled: enabled)
        await updatedSettings()
    }
    
    func getRoomsWithUserDefinedRules() async throws -> [String] {
        await notificationSettings.getRoomsWithUserDefinedRules(enabled: true)
    }
    
    func canPushEncryptedEventsToDevice() async -> Bool {
        await notificationSettings.canPushEncryptedEventToDevice()
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

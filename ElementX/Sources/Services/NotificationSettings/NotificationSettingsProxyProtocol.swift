//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import Foundation
import MatrixRustSDK

enum NotificationSettingsProxyCallback {
    case settingsDidChange
}

// sourcery: AutoMockable
protocol NotificationSettingsProxyProtocol {
    var callbacks: PassthroughSubject<NotificationSettingsProxyCallback, Never> { get }
    
    func getNotificationSettings(roomId: String, isEncrypted: Bool, isOneToOne: Bool) async throws -> RoomNotificationSettingsProxyProtocol
    func setNotificationMode(roomId: String, mode: RoomNotificationModeProxy) async throws
    func getUserDefinedRoomNotificationMode(roomId: String) async throws -> RoomNotificationModeProxy?
    func getDefaultRoomNotificationMode(isEncrypted: Bool, isOneToOne: Bool) async -> RoomNotificationModeProxy
    func setDefaultRoomNotificationMode(isEncrypted: Bool, isOneToOne: Bool, mode: RoomNotificationModeProxy) async throws
    func restoreDefaultNotificationMode(roomId: String) async throws
    func unmuteRoom(roomId: String, isEncrypted: Bool, isOneToOne: Bool) async throws
    func isRoomMentionEnabled() async throws -> Bool
    func setRoomMentionEnabled(enabled: Bool) async throws
    func isCallEnabled() async throws -> Bool
    func setCallEnabled(enabled: Bool) async throws
    func isInviteForMeEnabled() async throws -> Bool
    func setInviteForMeEnabled(enabled: Bool) async throws
    func getRoomsWithUserDefinedRules() async throws -> [String]
    func canPushEncryptedEventsToDevice() async -> Bool
}

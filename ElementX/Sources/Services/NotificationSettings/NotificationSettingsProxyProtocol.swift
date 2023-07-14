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

enum NotificationSettingsProxyCallback {
    case settingsDidChange
}

// sourcery: AutoMockable
protocol NotificationSettingsProxyProtocol {
    var callbacks: PassthroughSubject<NotificationSettingsProxyCallback, Never> { get }
    
    func getNotificationSettings(roomId: String, isEncrypted: Bool, activeMembersCount: UInt64) async throws -> RoomNotificationSettingsProxyProtocol
    func setNotificationMode(roomId: String, mode: RoomNotificationMode) async throws
    func getDefaultNotificationRoomMode(isEncrypted: Bool, activeMembersCount: UInt64) async -> RoomNotificationMode
    func restoreDefaultNotificationMode(roomId: String) async throws
    func containsKeywordsRules() async -> Bool
    func unmuteRoom(roomId: String, isEncrypted: Bool, activeMembersCount: UInt64) async throws
    func isRoomMentionEnabled() async throws -> Bool
    func setRoomMentionEnabled(enabled: Bool) async throws
    func isUserMentionEnabled() async throws -> Bool
    func setUserMentionEnabled(enabled: Bool) async throws
    func isCallEnabled() async throws -> Bool
    func setCallEnabled(enabled: Bool) async throws
}

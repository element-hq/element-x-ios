//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation
import MatrixRustSDK

struct RoomNotificationSettingsProxy: RoomNotificationSettingsProxyProtocol {
    private let roomNotificationSettings: RoomNotificationSettings
    
    var mode: RoomNotificationModeProxy {
        RoomNotificationModeProxy.from(roomNotificationMode: roomNotificationSettings.mode)
    }
    
    var isDefault: Bool {
        roomNotificationSettings.isDefault
    }
    
    init(roomNotificationSettings: RoomNotificationSettings) {
        self.roomNotificationSettings = roomNotificationSettings
    }
}

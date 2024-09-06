//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation
import MatrixRustSDK

struct RoomNotificationSettingsProxyMockConfiguration {
    var mode: RoomNotificationModeProxy = .allMessages
    var isDefault = true
}

extension RoomNotificationSettingsProxyMock {
    convenience init(with configuration: RoomNotificationSettingsProxyMockConfiguration) {
        self.init()

        isDefault = configuration.isDefault
        mode = configuration.mode
    }
}

//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRustSDK

// sourcery: AutoMockable
protocol RoomNotificationSettingsProxyProtocol {
    var mode: RoomNotificationModeProxy { get }
    var isDefault: Bool { get }
}

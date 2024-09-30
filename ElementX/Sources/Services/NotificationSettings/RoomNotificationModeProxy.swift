//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation
import MatrixRustSDK

enum RoomNotificationModeProxy: String, CaseIterable {
    case allMessages
    case mentionsAndKeywordsOnly
    case mute
}

extension RoomNotificationModeProxy {
    static func from(roomNotificationMode: RoomNotificationMode) -> Self {
        switch roomNotificationMode {
        case .allMessages:
            return .allMessages
        case .mentionsAndKeywordsOnly:
            return .mentionsAndKeywordsOnly
        case .mute:
            return .mute
        }
    }
    
    var roomNotificationMode: RoomNotificationMode {
        switch self {
        case .allMessages:
            return .allMessages
        case .mentionsAndKeywordsOnly:
            return .mentionsAndKeywordsOnly
        case .mute:
            return .mute
        }
    }
}

//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation
import UIKit

enum AvatarSize {
    case user(on: UserAvatarSizeOnScreen)
    case room(on: RoomAvatarSizeOnScreen)
    //  custom
    case custom(CGFloat)

    /// Value in UIKit points
    var value: CGFloat {
        switch self {
        case .user(let screen):
            return screen.value
        case .room(let screen):
            return screen.value
        case .custom(let val):
            return val
        }
    }

    /// Value in pixels by using the scale of the main screen
    var scaledValue: CGFloat {
        value * UIScreen.main.scale
    }
}

enum UserAvatarSizeOnScreen {
    case timeline
    case home
    case settings
    case roomDetails
    case dmDetails
    case startChat
    case memberDetails
    case inviteUsers
    case readReceipt
    case readReceiptSheet
    case editUserDetails
    case suggestions
    case blockedUsers

    var value: CGFloat {
        switch self {
        case .readReceipt:
            return 16
        case .readReceiptSheet:
            return 32
        case .timeline:
            return 32
        case .home:
            return 32
        case .suggestions:
            return 32
        case .blockedUsers:
            return 32
        case .settings:
            return 52
        case .roomDetails:
            return 44
        case .startChat:
            return 36
        case .memberDetails:
            return 96
        case .inviteUsers:
            return 56
        case .editUserDetails:
            return 96
        case .dmDetails:
            return 75
        }
    }
}

enum RoomAvatarSizeOnScreen {
    case timeline
    case home
    case messageForwarding
    case globalSearch
    case details
    case notificationSettings
    case roomDirectorySearch
    case joinRoom

    var value: CGFloat {
        switch self {
        case .notificationSettings:
            return 30
        case .timeline:
            return 32
        case .roomDirectorySearch:
            return 32
        case .messageForwarding:
            return 36
        case .globalSearch:
            return 36
        case .home:
            return 52
        case .details:
            return 96
        case .joinRoom:
            return 96
        }
    }
}

extension AvatarSize {
    var scaledSize: CGSize {
        CGSize(width: scaledValue, height: scaledValue)
    }
}

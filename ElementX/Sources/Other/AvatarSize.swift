//
// Copyright 2022 New Vector Ltd
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
    case startChat
    case memberDetails
    case inviteUsers
    case readReceipt
    case editUserDetails

    var value: CGFloat {
        switch self {
        case .readReceipt:
            return 16
        case .timeline:
            return 32
        case .home:
            return 32
        case .settings:
            return 52
        case .roomDetails:
            return 44
        case .startChat:
            return 36
        case .memberDetails:
            return 70
        case .inviteUsers:
            return 56
        case .editUserDetails:
            return 96
        }
    }
}

enum RoomAvatarSizeOnScreen {
    case timeline
    case home
    case messageForwarding
    case details
    case notificationSettings

    var value: CGFloat {
        switch self {
        case .notificationSettings:
            return 30
        case .timeline:
            return 32
        case .messageForwarding:
            return 36
        case .home:
            return 52
        case .details:
            return 70
        }
    }
}

extension AvatarSize {
    var size: CGSize {
        CGSize(width: value, height: value)
    }

    var scaledSize: CGSize {
        CGSize(width: scaledValue, height: scaledValue)
    }
}

//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import SwiftUI

enum Avatars {
    enum Size {
        case user(on: UserAvatarSizeOnScreen)
        case room(on: RoomAvatarSizeOnScreen)
        ///  custom
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
        
        var scaledSize: CGSize {
            CGSize(width: scaledValue, height: scaledValue)
        }
    }
    
    @MainActor
    static func generatePlaceholderAvatarImageData(name: String, id: String, size: CGSize) -> Data? {
        let image = PlaceholderAvatarImage(name: name, contentID: id)
            .clipShape(Circle())
            .frame(width: size.width, height: size.height)
        
        let renderer = ImageRenderer(content: image)
        
        // Specify the scale so the image is rendered correctly. We don't have access to the screen
        // here so a hardcoded 3.0 will have to do
        renderer.scale = 3.0
        
        guard let image = renderer.uiImage else {
            MXLog.info("Generating notification icon placeholder failed")
            return nil
        }
        
        return image.pngData()
    }
}

enum UserAvatarSizeOnScreen {
    case chats
    case spaces
    case timeline
    case settings
    case roomDetails
    case roomMembersList
    case roomChangeRoles
    case dmDetails
    case startChat
    case memberDetails
    case inviteUsers
    case readReceipt
    case readReceiptSheet
    case editUserDetails
    case spaceHeader
    case completionSuggestions
    case blockedUsers
    case knockingUsersBannerStack
    case knockingUserBanner
    case knockingUserList
    case mediaPreviewDetails
    case sendInviteConfirmation
    case sessionVerification
    case threadSummary
    case map

    var value: CGFloat {
        switch self {
        case .readReceipt:
            16
        case .spaceHeader:
            20
        case .threadSummary:
            24
        case .knockingUsersBannerStack:
            28
        case .chats, .spaces, .map,
             .timeline, .readReceiptSheet, .completionSuggestions,
             .blockedUsers, .roomMembersList, .knockingUserBanner,
             .mediaPreviewDetails:
            32
        case .startChat:
            36
        case .roomDetails:
            44
        case .inviteUsers, .knockingUserList, .sessionVerification,
             .settings:
            52
        case .roomChangeRoles:
            56
        case .sendInviteConfirmation:
            64
        case .dmDetails:
            75
        case .memberDetails, .editUserDetails:
            96
        }
    }
}

enum RoomAvatarSizeOnScreen {
    case chats
    case spaces
    case spaceSettings
    case spaceFilters
    case authorizedSpaces
    case timeline
    case leaveSpace
    case messageForwarding
    case globalSearch
    case roomSelection
    case details
    case notificationSettings
    case roomDirectorySearch
    case joinRoom
    case spaceHeader
    case spaceAddRooms
    case spaceAddRoomsSelected
    case completionSuggestions
    case createRoomSelectSpace

    var value: CGFloat {
        switch self {
        case .notificationSettings:
            30
        case .timeline, .leaveSpace, .roomDirectorySearch,
             .completionSuggestions, .authorizedSpaces, .createRoomSelectSpace,
             .spaceFilters:
            32
        case .messageForwarding, .globalSearch, .roomSelection,
             .spaceAddRooms:
            36
        case .chats, .spaces, .spaceSettings,
             .spaceAddRoomsSelected:
            52
        case .joinRoom, .spaceHeader:
            64
        case .details:
            96
        }
    }
}

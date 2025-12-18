//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRustSDK

enum RoomChangePermissionsScreenViewModelAction {
    case complete
}

struct RoomChangePermissionsScreenViewState: BindableState {
    /// The current permissions that are set on the room.
    var currentPermissions: RoomPermissions
    
    var bindings: RoomChangePermissionsScreenViewStateBindings
    
    /// Whether or not there are and changes to be saved.
    var hasChanges: Bool {
        bindings.settings.values
            .flatMap { $0 }
            .contains { currentPermissions[keyPath: $0.keyPath] != $0.value }
    }
}

struct RoomChangePermissionsScreenViewStateBindings: BindableState {
    /// All of the settings shown for this screen.
    var settings: [RoomChangePermissionsScreenGroup: [RoomPermissionsSetting]]
    /// Information about the currently displayed alert.
    var alertInfo: AlertInfo<RoomChangePermissionsScreenAlertType>?
}

enum RoomChangePermissionsScreenAlertType {
    /// A confirmation that the user would like to discard any unsaved changes.
    case discardChanges
    /// The generic error message.
    case generic
}

enum RoomChangePermissionsScreenViewAction {
    /// Save the permissions.
    case save
    /// Discard any changes and hide the screen.
    case cancel
}

enum RoomChangePermissionsScreenGroup: CaseIterable {
    case memberModeration
    case roomDetails
    case messagesAndContent
    case manageSpace
    
    var name: String {
        switch self {
        case .roomDetails: return L10n.screenRoomChangePermissionsRoomDetails
        case .memberModeration: return L10n.screenRoomChangePermissionsMemberModeration
        case .messagesAndContent: return L10n.screenRoomChangePermissionsMessagesAndContent
        case .manageSpace: return L10n.screenRoomChangePermissionsManageSpace
        }
    }
}

extension RoomChangePermissionsScreenViewState {
    /// Creates a view state for a particular group of permissions.
    /// - Parameters:
    ///   - currentPermissions: The current permissions for the room.
    ///   - isSpace: if the room is a space or a normal room.
    init(ownPowerLevel: RoomPowerLevel, currentPermissions: RoomPermissions, isSpace: Bool) {
        var settings = [RoomChangePermissionsScreenGroup: [RoomPermissionsSetting]]()
        for group in RoomChangePermissionsScreenGroup.allCases {
            switch group {
            case .roomDetails:
                settings[group] = [
                    RoomPermissionsSetting(title: L10n.screenRoomChangePermissionsRoomName,
                                           value: currentPermissions.roomName,
                                           ownPowerLevel: ownPowerLevel,
                                           keyPath: \.roomName),
                    RoomPermissionsSetting(title: L10n.screenRoomChangePermissionsRoomAvatar,
                                           value: currentPermissions.roomAvatar,
                                           ownPowerLevel: ownPowerLevel,
                                           keyPath: \.roomAvatar),
                    RoomPermissionsSetting(title: L10n.screenRoomChangePermissionsRoomTopic,
                                           value: currentPermissions.roomTopic,
                                           ownPowerLevel: ownPowerLevel,
                                           keyPath: \.roomTopic)
                ]
                
            case .memberModeration:
                settings[group] = [
                    RoomPermissionsSetting(title: L10n.screenRoomChangePermissionsInvitePeople,
                                           value: currentPermissions.invite,
                                           ownPowerLevel: ownPowerLevel,
                                           keyPath: \.invite),
                    RoomPermissionsSetting(title: L10n.screenRoomChangePermissionsRemovePeople,
                                           value: currentPermissions.kick,
                                           ownPowerLevel: ownPowerLevel,
                                           keyPath: \.kick),
                    RoomPermissionsSetting(title: L10n.screenRoomChangePermissionsBanPeople,
                                           value: currentPermissions.ban,
                                           ownPowerLevel: ownPowerLevel,
                                           keyPath: \.ban)
                ]
            case .messagesAndContent:
                if !isSpace {
                    settings[group] = [
                        RoomPermissionsSetting(title: L10n.screenRoomChangePermissionsSendMessages,
                                               value: currentPermissions.eventsDefault,
                                               ownPowerLevel: ownPowerLevel,
                                               keyPath: \.eventsDefault),
                        RoomPermissionsSetting(title: L10n.screenRoomChangePermissionsDeleteMessages,
                                               value: currentPermissions.redact,
                                               ownPowerLevel: ownPowerLevel,
                                               keyPath: \.redact)
                    ]
                }
            case .manageSpace:
                if isSpace {
                    settings[group] = [
                        RoomPermissionsSetting(title: L10n.screenRoomChangePermissionsManageSpaceRooms,
                                               value: currentPermissions.spaceChild,
                                               ownPowerLevel: ownPowerLevel,
                                               keyPath: \.spaceChild)
                    ]
                }
            }
        }
        self.init(currentPermissions: currentPermissions, bindings: .init(settings: settings))
    }
}

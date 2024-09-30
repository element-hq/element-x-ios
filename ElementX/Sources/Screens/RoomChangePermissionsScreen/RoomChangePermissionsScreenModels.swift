//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation
import MatrixRustSDK

enum RoomChangePermissionsScreenViewModelAction {
    case complete
}

struct RoomChangePermissionsScreenViewState: BindableState {
    /// The screen's title.
    let title: String
    /// The current permissions that are set on the room.
    var currentPermissions: RoomPermissions
    
    var bindings: RoomChangePermissionsScreenViewStateBindings
    
    /// Whether or not there are and changes to be saved.
    var hasChanges: Bool {
        bindings.settings.contains { currentPermissions[keyPath: $0.keyPath] != $0.value }
    }
}

struct RoomChangePermissionsScreenViewStateBindings: BindableState {
    /// All of the settings shown for this screen.
    var settings: [RoomPermissionsSetting]
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

extension RoomChangePermissionsScreenViewState {
    /// Creates a view state for a particular group of permissions.
    /// - Parameters:
    ///   - currentPermissions: The current permissions for the room.
    ///   - group: The group of permissions that should be shown in the screen.
    init(currentPermissions: RoomPermissions, group: RoomRolesAndPermissionsScreenPermissionsGroup) {
        switch group {
        case .roomDetails:
            let settings = [
                RoomPermissionsSetting(title: L10n.screenRoomChangePermissionsRoomName,
                                       value: currentPermissions.roomName,
                                       keyPath: \.roomName),
                RoomPermissionsSetting(title: L10n.screenRoomChangePermissionsRoomAvatar,
                                       value: currentPermissions.roomAvatar,
                                       keyPath: \.roomAvatar),
                RoomPermissionsSetting(title: L10n.screenRoomChangePermissionsRoomTopic,
                                       value: currentPermissions.roomTopic,
                                       keyPath: \.roomTopic)
            ]
            
            self.init(title: L10n.screenRoomChangePermissionsRoomDetails, currentPermissions: currentPermissions, bindings: .init(settings: settings))
        
        case .messagesAndContent:
            let settings = [
                RoomPermissionsSetting(title: L10n.screenRoomChangePermissionsSendMessages,
                                       value: currentPermissions.eventsDefault,
                                       keyPath: \.eventsDefault),
                RoomPermissionsSetting(title: L10n.screenRoomChangePermissionsDeleteMessages,
                                       value: currentPermissions.redact,
                                       keyPath: \.redact)
            ]
            
            self.init(title: L10n.screenRoomChangePermissionsMessagesAndContent, currentPermissions: currentPermissions, bindings: .init(settings: settings))
        
        case .memberModeration:
            let settings = [
                RoomPermissionsSetting(title: L10n.screenRoomChangePermissionsInvitePeople,
                                       value: currentPermissions.invite,
                                       keyPath: \.invite),
                RoomPermissionsSetting(title: L10n.screenRoomChangePermissionsRemovePeople,
                                       value: currentPermissions.kick,
                                       keyPath: \.kick),
                RoomPermissionsSetting(title: L10n.screenRoomChangePermissionsBanPeople,
                                       value: currentPermissions.ban,
                                       keyPath: \.ban)
            ]
            
            self.init(title: L10n.screenRoomChangePermissionsMemberModeration, currentPermissions: currentPermissions, bindings: .init(settings: settings))
        }
    }
}

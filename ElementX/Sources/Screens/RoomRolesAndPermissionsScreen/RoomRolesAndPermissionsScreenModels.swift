//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

enum RoomRolesAndPermissionsScreenViewModelAction {
    /// The user would like to edit member roles.
    case editRoles(RoomRolesAndPermissionsScreenRole)
    /// The user would like to edit room permissions.
    case editPermissions(permissions: RoomPermissions, group: RoomRolesAndPermissionsScreenPermissionsGroup)
    /// The user has demoted themself.
    case demotedOwnUser
}

struct RoomRolesAndPermissionsScreenViewState: BindableState {
    /// The number of administrators in the room.
    var administratorCount: Int?
    /// The number of moderators in the room.
    var moderatorCount: Int?
    /// The permissions of the room when loaded.
    var permissions: RoomPermissions?
    var bindings = RoomRolesAndPermissionsScreenViewStateBindings()
}

struct RoomRolesAndPermissionsScreenViewStateBindings {
    var alertInfo: AlertInfo<RoomRolesAndPermissionsScreenAlertType>?
}

enum RoomRolesAndPermissionsScreenAlertType {
    /// Ask the user which role they would like to demote themself to.
    case editOwnRole
    /// Confirm that the user would like to reset the room's permissions.
    case resetConfirmation
    /// An error occurred.
    case error
}

enum RoomRolesAndPermissionsScreenViewAction {
    case editRoles(RoomRolesAndPermissionsScreenRole)
    case editOwnUserRole
    case editPermissions(RoomRolesAndPermissionsScreenPermissionsGroup)
    case reset
}

enum RoomRolesAndPermissionsScreenRole {
    case administrators
    case moderators
}

enum RoomRolesAndPermissionsScreenPermissionsGroup {
    case roomDetails
    case messagesAndContent
    case memberModeration
}

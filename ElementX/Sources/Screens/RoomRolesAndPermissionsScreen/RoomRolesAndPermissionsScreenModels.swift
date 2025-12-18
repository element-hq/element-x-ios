//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

enum RoomRolesAndPermissionsScreenViewModelAction {
    /// The user would like to edit member roles.
    case editRoles(RoomRolesAndPermissionsScreenRole)
    /// The user would like to edit room permissions.
    case editPermissions(ownPowerLevel: RoomPowerLevel, permissions: RoomPermissions)
    /// The user has demoted themself.
    case demotedOwnUser
}

struct RoomRolesAndPermissionsScreenViewState: BindableState {
    var ownPowerLevel: RoomPowerLevel
    
    var administratorsAndOwnersCount: Int?
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
    case editPermissions
    case reset
}

enum RoomRolesAndPermissionsScreenRole: Hashable {
    case administrators
    case moderators
}

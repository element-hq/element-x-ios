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

enum RoomRolesAndPermissionsScreenViewModelAction {
    /// The user would like to edit member roles.
    case editRoles(RoomRolesAndPermissionsScreenRole)
    /// The user would like to edit room permissions.
    case editPermissions(RoomRolesAndPermissionsScreenPermissionsGroup)
    /// The user has demoted themself.
    case demotedOwnUser
}

struct RoomRolesAndPermissionsScreenViewState: BindableState {
    /// The number of administrators in the room.
    var administratorCount: Int?
    /// The number of moderators in the room.
    var moderatorCount: Int?
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

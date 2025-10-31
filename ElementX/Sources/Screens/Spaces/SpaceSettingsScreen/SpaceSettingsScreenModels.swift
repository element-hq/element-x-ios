//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

enum SpaceSettingsScreenViewModelAction { }

struct SpaceSettingsScreenViewState: BindableState {
    var details: RoomDetails
    
    var joinedMembersCount: Int
    var hasMemberIdentityVerificationStateViolations = false
    
    var canEditBaseInfo = false
    var canEditRolesOrPermissions = false
}

enum SpaceSettingsScreenViewAction {
    case processTapEdit
    case processTapSecurity
    case processTapPeople
    case processTapRolesAndPermissions
    case processTapLeave
}

//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

enum SpaceScreenViewModelAction {
    case selectSpace(SpaceRoomListProxyProtocol)
    case selectUnjoinedSpace(SpaceServiceRoomProtocol)
    case selectRoom(roomID: String)
    case leftSpace
    case presentRolesAndPermissions(roomProxy: JoinedRoomProxyProtocol)
    case displayMembers(roomProxy: JoinedRoomProxyProtocol)
    case displaySpaceSettings(roomProxy: JoinedRoomProxyProtocol)
}

struct SpaceScreenViewState: BindableState {
    var space: SpaceServiceRoomProtocol
    
    var permalink: URL?
    var roomProxy: JoinedRoomProxyProtocol?
    
    var isPaginating = false
    var rooms: [SpaceServiceRoomProtocol]
    var selectedSpaceRoomID: String?
    var joiningRoomIDs: Set<String> = []
    
    var canEditBaseInfo = false
    var canEditRolesAndPermissions = false
    var canEditSecurityAndPrivacy = false
    
    var isSpaceManagementEnabled: Bool {
        canEditBaseInfo || canEditRolesAndPermissions || canEditSecurityAndPrivacy
    }
    
    var bindings = SpaceScreenViewStateBindings()
}

struct SpaceScreenViewStateBindings {
    var leaveSpaceViewModel: LeaveSpaceViewModel?
}

enum SpaceScreenViewAction {
    case spaceAction(SpaceRoomCell.Action)
    case leaveSpace
    case spaceSettings(roomProxy: JoinedRoomProxyProtocol)
    case displayMembers(roomProxy: JoinedRoomProxyProtocol)
}

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
    case selectUnjoinedSpace(SpaceRoomProxyProtocol)
    case selectRoom(roomID: String)
    case leftSpace
    case displayMembers(roomProxy: JoinedRoomProxyProtocol)
    case displaySpaceSettings(roomProxy: JoinedRoomProxyProtocol)
}

struct SpaceScreenViewState: BindableState {
    var space: SpaceRoomProxyProtocol
    
    var permalink: URL?
    var roomProxy: JoinedRoomProxyProtocol?
    
    var isPaginating = false
    var rooms: [SpaceRoomProxyProtocol]
    var selectedSpaceRoomID: String?
    var joiningRoomIDs: Set<String> = []
    
    var isSpaceManagementEnabled = false
    
    var bindings = SpaceScreenViewStateBindings()
}

struct SpaceScreenViewStateBindings {
    var leaveHandle: LeaveSpaceHandleProxy?
}

enum SpaceScreenViewAction {
    case spaceAction(SpaceRoomCell.Action)
    case leaveSpace
    case deselectAllLeaveRoomDetails
    case selectAllLeaveRoomDetails
    case toggleLeaveSpaceRoomDetails(id: String)
    case confirmLeaveSpace
    case spaceSettings
    case displayMembers(roomProxy: JoinedRoomProxyProtocol)
}

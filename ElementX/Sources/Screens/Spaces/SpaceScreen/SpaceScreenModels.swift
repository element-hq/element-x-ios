//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

enum SpaceScreenViewModelAction {
    case selectSpace(SpaceRoomListProxyProtocol)
    case selectUnjoinedSpace(SpaceServiceRoom)
    case selectRoom(roomID: String)
    case leftSpace
    case presentRolesAndPermissions(roomProxy: JoinedRoomProxyProtocol)
    case presentTransferOwnership(roomProxy: JoinedRoomProxyProtocol)
    case displayMembers(roomProxy: JoinedRoomProxyProtocol)
    case displaySpaceSettings(roomProxy: JoinedRoomProxyProtocol)
    case addExistingChildren
    case displayCreateChildRoomFlow(space: SpaceServiceRoom)
}

struct SpaceScreenViewState: BindableState {
    var space: SpaceServiceRoom
    
    var permalink: URL?
    var roomProxy: JoinedRoomProxyProtocol?
    
    var paginationState: PaginationState = .idle
    var rooms: [SpaceServiceRoom]
    var selectedSpaceRoomID: String?
    var joiningRoomIDs: Set<String> = []
    
    var canEditBaseInfo = false
    var canEditRolesAndPermissions = false
    var canEditSecurityAndPrivacy = false
    var canEditChildren = false
    var canCreateRoom = false
    
    var editMode: EditMode = .inactive
    var editModeSelectedIDs: Set<String> = []
    var editModeRemovedIDs: Set<String> = []
    
    var bindings = SpaceScreenViewStateBindings()
    
    var shouldShowEmptyState: Bool {
        rooms.isEmpty && paginationState == .endReached && canEditChildren
    }
    
    var visibleRooms: [SpaceServiceRoom] {
        if editMode == .inactive {
            rooms
        } else {
            rooms.filter { !$0.isSpace && !editModeRemovedIDs.contains($0.id) }
        }
    }
    
    var isSpaceManagementEnabled: Bool {
        canEditBaseInfo || canEditRolesAndPermissions || canEditSecurityAndPrivacy
    }
    
    func isSpaceIDSelected(_ spaceID: String) -> Bool {
        selectedSpaceRoomID == spaceID || editModeSelectedIDs.contains(spaceID)
    }
}

struct SpaceScreenViewStateBindings {
    var isPresentingRemoveChildrenConfirmation = false
    var leaveSpaceViewModel: LeaveSpaceViewModel?
}

enum SpaceScreenViewAction {
    case spaceAction(SpaceRoomCell.Action)
    case leaveSpace
    case spaceSettings(roomProxy: JoinedRoomProxyProtocol)
    case displayMembers(roomProxy: JoinedRoomProxyProtocol)
    case addExistingRooms
    case createChildRoom
    case manageChildren
    case removeSelectedChildren
    case confirmRemoveSelectedChildren
    case finishManagingChildren
}

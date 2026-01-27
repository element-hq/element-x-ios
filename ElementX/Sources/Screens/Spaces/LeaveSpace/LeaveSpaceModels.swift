//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

enum LeaveSpaceViewAction {
    case confirmLeaveSpace
    case deselectAll
    case selectAll
    case toggleRoom(roomID: String)
    case rolesAndPermissions
    case transferOwnership
    case cancel
}

struct LeaveSpaceViewState: BindableState {
    let spaceName: String
    let canEditRolesAndPermissions: Bool
    let leaveHandle: LeaveSpaceHandleProxy
    
    var title: String {
        switch leaveHandle.mode {
        case .spaceNeedsNewOwner(let useTransferOwnershipFlow):
            useTransferOwnershipFlow ? L10n.leaveRoomAlertSelectNewOwnerTitle : L10n.screenLeaveSpaceTitleLastAdmin(spaceName)
        default: L10n.screenLeaveSpaceTitle(spaceName)
        }
    }
    
    var subtitle: String? {
        switch leaveHandle.mode {
        case .manyRooms: L10n.screenLeaveSpaceSubtitle
        case .roomsNeedNewOwner: L10n.screenLeaveSpaceSubtitleOnlyLastAdmin
        case .noRooms: nil
        case .spaceNeedsNewOwner(let useTransferOwnershipFlow):
            useTransferOwnershipFlow ? L10n.screenLeaveSpaceSubtitleLastOwner(spaceName) : L10n.screenLeaveSpaceSubtitleLastAdmin
        }
    }
    
    var confirmationTitle: String {
        let selectedCount = leaveHandle.selectedCount
        return selectedCount > 0 ? L10n.screenLeaveSpaceSubmit(selectedCount) : L10n.actionLeaveSpace
    }
}

enum LeaveSpaceViewModelAction {
    case didLeaveSpace
    case presentRolesAndPermissions
    case presentTransferOwnership
    case didCancel
}

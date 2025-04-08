//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

enum ManageRoomMemberSheetViewModelAction: Equatable {
    case dismiss(shouldShowDetails: Bool)
}

struct ManageRoomMemberSheetViewState: BindableState {
    let member: RoomMemberDetails
    let canKick: Bool
    let canBan: Bool
    
    var bindings = ManageRoomMemberSheetViewStateBindings()
}

struct ManageRoomMemberSheetViewStateBindings {
    var alertInfo: AlertInfo<ManageRoomMemberSheetViewAlertType>?
}

enum ManageRoomMemberSheetViewAlertType {
    case kick
    case ban
}

enum ManageRoomMemberSheetViewAction {
    case kick
    case ban
    case displayDetails
}

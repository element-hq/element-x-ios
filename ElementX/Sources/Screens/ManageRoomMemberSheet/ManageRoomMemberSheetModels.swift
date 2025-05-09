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
    let details: ManageRoomMemberDetails
    
    var canKick: Bool {
        guard case let .memberDetails(_, canKick, _) = details else {
            return false
        }
        return canKick
    }
    
    var canBanAndUnban: Bool {
        guard case let .memberDetails(_, _, canBan) = details else {
            return false
        }
        return canBan
    }
    
    var isMemberBanned: Bool {
        guard case let .memberDetails(member, _, _) = details else {
            return false
        }
        
        return member.isBanned
    }
    
    var bindings = ManageRoomMemberSheetViewStateBindings()
}

struct ManageRoomMemberSheetViewStateBindings {
    var alertInfo: AlertInfo<ManageRoomMemberSheetViewAlertType>?
}

enum ManageRoomMemberSheetViewAlertType {
    case kick
    case ban
    case unban
}

enum ManageRoomMemberSheetViewAction {
    case kick
    case ban
    case unban
    case displayDetails
}

enum ManageRoomMemberDetails {
    case memberDetails(roomMember: RoomMemberDetails, canKick: Bool, canBanAndUnban: Bool)
    case senderDetails(sender: TimelineItemSender)
    
    var id: String {
        switch self {
        case let .memberDetails(roomMember, _, _):
            return roomMember.id
        case let .senderDetails(sender):
            return sender.id
        }
    }
}

//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

enum ManageRoomMemberSheetViewModelAction: Equatable {
    case dismiss(shouldShowDetails: Bool)
}

struct ManageRoomMemberSheetViewState: BindableState {
    let memberDetails: ManageRoomMemberDetails
    let permissions: ManageRoomMemberPermissions
    
    var isBanUnbanDisabled: Bool {
        // This is a best effort check, if we haven't fetched the member yet we assume we can peform the action
        guard case let .memberDetails(member) = memberDetails else {
            return false
        }
        
        return permissions.ownPowerLevel <= member.powerLevel
    }
    
    var isKickDisabled: Bool {
        // This is a best effort check, if we haven't fetched the member yet we assume we can peform the action
        guard case let .memberDetails(member) = memberDetails else {
            return false
        }
        
        return !member.isActive || permissions.ownPowerLevel <= member.powerLevel
    }
    
    var isMemberBanned: Bool {
        // This is a best effort check, if we haven't fetched the member yet we assume the member is not banned
        guard case let .memberDetails(member) = memberDetails else {
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
    case memberDetails(roomMember: RoomMemberDetails)
    case loadingMemberDetails(sender: TimelineItemSender)
    
    var id: String {
        switch self {
        case let .memberDetails(roomMember):
            roomMember.id
        case let .loadingMemberDetails(sender):
            sender.id
        }
    }
    
    var name: String? {
        switch self {
        case let .memberDetails(roomMember):
            roomMember.name
        case let .loadingMemberDetails(sender):
            sender.displayName
        }
    }
}

struct ManageRoomMemberPermissions {
    let canKick: Bool
    let canBan: Bool
    let ownPowerLevel: RoomPowerLevel
}

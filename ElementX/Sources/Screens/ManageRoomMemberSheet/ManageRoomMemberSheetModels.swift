//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

enum ManageRoomMemberSheetViewModelAction: Equatable {
    case dismiss(shouldShowDetails: Bool)
}

struct ManageRoomMemberSheetViewState: BindableState {
    let memberDetails: ManageRoomMemberDetails
    let permissions: ManageRoomMemberPermissions
    var isOwnUser = false

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

        // Removing yourself is just leaving, so the power level comparison doesn't apply.
        if isOwnUser {
            return !member.isActive
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

    var memberRole: RoomRole? {
        guard case let .memberDetails(member) = memberDetails else {
            return nil
        }

        return member.role
    }

    /// The role is always shown when it isn't the default one, but is only shown for
    /// regular members when the user is able to promote them.
    var isRoleVisible: Bool {
        guard let memberRole else { return false }
        return memberRole != .user || isRoleEditable
    }

    var isRoleEditable: Bool {
        guard case let .memberDetails(member) = memberDetails, permissions.canEditRoles, member.isActive else {
            return false
        }

        // You can only demote yourself (and a creator can't be demoted at all).
        if isOwnUser {
            return member.role != .user && member.role != .creator
        }

        return permissions.ownPowerLevel > member.powerLevel
    }

    /// The roles the user is able to assign - anything up to their own power level.
    var availableRoles: [RoomRole] {
        [.owner, .administrator, .moderator, .user].filter { $0.powerLevel <= permissions.ownPowerLevel }
    }

    var bindings = ManageRoomMemberSheetViewStateBindings()
}

struct ManageRoomMemberSheetViewStateBindings {
    var alertInfo: AlertInfo<ManageRoomMemberSheetViewAlertType>?
    var mediaPreviewItem: MediaPreviewItem?
    var selectedRole: RoomRole = .user
}

enum ManageRoomMemberSheetViewAlertType {
    case kick
    case ban
    case unban
    case promoteToAdmin
    case promoteToOwner
    case demoteOwnUser
}

enum ManageRoomMemberSheetViewAction {
    case kick
    case ban
    case unban
    case updateRole(RoomRole)
    case changeOwnRole
    case displayDetails
    case displayAvatar(URL)
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
    var canEditRoles = false
    let ownPowerLevel: RoomPowerLevel
}

nonisolated extension RoomRole {
    var localizedTitle: String {
        switch self {
        case .creator, .owner:
            L10n.screenRoomMemberListRoleOwner
        case .administrator:
            L10n.screenRoomMemberListRoleAdministrator
        case .moderator:
            L10n.screenRoomMemberListRoleModerator
        case .user:
            L10n.screenRoomChangePermissionsEveryone
        }
    }
}

//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

enum RoomMembersListScreenViewModelAction {
    case selectMember(_ member: RoomMemberProxyProtocol)
    case invite
    
    var isSelectMember: Bool {
        switch self {
        case .selectMember:
            true
        default:
            false
        }
    }
}

/// The different modes that the screen can be in.
enum RoomMembersListScreenMode {
    /// The screen is showing invited and joined members.
    case members
    /// The screen is showing banned members (to mods/admins)
    case banned
}

struct RoomMemberListScreenEntry: Equatable {
    let member: RoomMemberDetails
    let verificationState: UserIdentityVerificationState
}

struct RoomMembersListScreenViewState: BindableState {
    private var joinedMembers: [RoomMemberListScreenEntry]
    private var invitedMembers: [RoomMemberListScreenEntry]
    private var bannedMembers: [RoomMemberListScreenEntry]
    
    let joinedMembersCount: Int
    var bannedMembersCount: Int {
        bannedMembers.count
    }
    
    var canInviteUsers = false
    var canKickUsers = false
    var canBanUsers = false
    
    var bindings: RoomMembersListScreenViewStateBindings
    
    init(joinedMembersCount: Int,
         joinedMembers: [RoomMemberListScreenEntry] = [],
         invitedMembers: [RoomMemberListScreenEntry] = [],
         bannedMembers: [RoomMemberListScreenEntry] = [],
         bindings: RoomMembersListScreenViewStateBindings) {
        self.joinedMembersCount = joinedMembersCount
        self.joinedMembers = joinedMembers
        self.invitedMembers = invitedMembers
        self.bannedMembers = bannedMembers
        self.bindings = bindings
    }
    
    var visibleJoinedMembers: [RoomMemberListScreenEntry] {
        joinedMembers
            .filter { $0.member.matches(searchQuery: bindings.searchQuery) }
    }
    
    var visibleInvitedMembers: [RoomMemberListScreenEntry] {
        invitedMembers
            .filter { $0.member.matches(searchQuery: bindings.searchQuery) }
    }
    
    var visibleBannedMembers: [RoomMemberListScreenEntry] {
        bannedMembers
            .filter { $0.member.matches(searchQuery: bindings.searchQuery) }
    }
    
    var shouldShowEmptyState: Bool {
        switch bindings.mode {
        case .banned:
            visibleBannedMembers.count == 0
        case .members:
            visibleInvitedMembers.count + visibleJoinedMembers.count == 0
        }
    }
}

struct RoomMembersListScreenViewStateBindings {
    var searchQuery = ""
    /// The current mode the screen is in.
    var mode: RoomMembersListScreenMode = .members
    /// A sheet model for the selected member to kick, ban, promote etc.
    var manageMemeberViewModel: ManageRoomMemberSheetViewModel?

    /// Information describing the currently displayed alert.
    var alertInfo: AlertInfo<RoomMembersListScreenAlertType>?
}

enum RoomMembersListScreenViewAction {
    case selectMember(RoomMemberDetails)
    case invite
}

enum RoomMembersListScreenAlertType: Hashable {
    case unbanConfirmation(RoomMemberDetails)
    case kickConfirmation
    case banConfirmation
}

//
// Copyright 2022-2024 New Vector Ltd.
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
    var bannedMembersCount: Int { bannedMembers.count }
    
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
}

struct RoomMembersListScreenViewStateBindings {
    var searchQuery = ""
    /// The current mode the screen is in.
    var mode: RoomMembersListScreenMode = .members
    /// A selected member to kick, ban, promote etc.
    var memberToManage: RoomMembersListScreenManagementDetails?

    /// Information describing the currently displayed alert.
    var alertInfo: AlertInfo<RoomMembersListScreenAlertType>?
}

/// Information about managing a particular room member.
struct RoomMembersListScreenManagementDetails: Identifiable {
    var id: String { member.id }
    
    /// The member that is being managed.
    let member: RoomMemberDetails
    
    /// A management action that can be performed on the member.
    enum Action { case kick, ban }
    /// The management actions available for `member`.
    let actions: [Action]
}

enum RoomMembersListScreenViewAction {
    case selectMember(RoomMemberDetails)
    case showMemberDetails(RoomMemberDetails)
    case kickMember(RoomMemberDetails)
    case banMember(RoomMemberDetails)
    case unbanMember(RoomMemberDetails)
    case invite
}

enum RoomMembersListScreenAlertType: Hashable {
    case unbanConfirmation(RoomMemberDetails)
}

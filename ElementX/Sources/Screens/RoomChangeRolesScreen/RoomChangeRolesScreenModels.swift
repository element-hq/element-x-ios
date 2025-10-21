//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Collections
import Foundation

enum RoomChangeRolesScreenViewModelAction {
    case complete
}

struct RoomChangeRolesScreenViewState: BindableState {
    /// The screen's current mode (which role we are promoting/demoting users to/from.
    let mode: RoomRole
    /// The current user's role.
    var ownRole: RoomRole
    /// All of the room's members who are currently owners or creators.
    var owners: [RoomMemberDetails] = []
    /// All of the room's members who are currently admins.
    var administrators: [RoomMemberDetails] = []
    /// All of the room's members who are currently moderators.
    var moderators: [RoomMemberDetails] = []
    /// All of the room's members who are currently neither an admin or moderator.
    var users: [RoomMemberDetails] = []
    
    var bindings = RoomChangeRolesScreenViewStateBindings()
    
    /// The members selected for promotion to the current role.
    var membersToPromote: Set<RoomMemberDetails> = []
    /// The member selected for demotion back to a regular user.
    var membersToDemote: Set<RoomMemberDetails> = []
    
    /// The last member added to the carousel at the top of the screen.
    var lastPromotedMember: RoomMemberDetails?
    
    /// The screen's title.
    var title: String {
        switch mode {
        case .creator:
            "" // The screen can't be configured with this role.
        case .owner:
            L10n.screenRoomChangeRoleOwnersTitle
        case .administrator:
            switch ownRole {
            case .creator:
                L10n.screenRoomChangeRoleAdministratorsOrOwnersTitle
            default:
                L10n.screenRoomChangeRoleAdministratorsTitle
            }
        case .moderator:
            L10n.screenRoomChangeRoleModeratorsTitle
        case .user:
            "" // The screen can't be configured with this role.
        }
    }
    
    var visibleOwners: [RoomMemberDetails] {
        owners.filter { $0.matches(searchQuery: bindings.searchQuery) }
    }
    
    /// The visible admins in the screen (after searching).
    var visibleAdministrators: [RoomMemberDetails] {
        administrators.filter { $0.matches(searchQuery: bindings.searchQuery) }
    }
    
    /// The visible mods in the screen (after searching).
    var visibleModerators: [RoomMemberDetails] {
        moderators.filter { $0.matches(searchQuery: bindings.searchQuery) }
    }
    
    /// The visible regular users in the screen (after searching).
    var visibleUsers: [RoomMemberDetails] {
        users.filter { $0.matches(searchQuery: bindings.searchQuery) }
    }
    
    /// All of the members who will gain/keep this screen's role after saving any changes.
    var membersWithRole: [RoomMemberDetails] {
        let members = owners + administrators + moderators + users
        return members.filter(isMemberSelected)
    }
    
    /// Whether or not any changes have been made to the members.
    var hasChanges: Bool {
        !membersToPromote.isEmpty || !membersToDemote.isEmpty
    }
    
    /// Whether or not the user is searching.
    var isSearching: Bool {
        !bindings.searchQuery.isEmpty
    }
    
    /// Whether or not a specific member has this screen's role.
    func isMemberSelected(_ member: RoomMemberDetails) -> Bool {
        guard !membersToDemote.contains(member) else { return false }
        return member.role >= mode || membersToPromote.contains(member)
    }
    
    func isMemberDisabled(_ member: RoomMemberDetails) -> Bool {
        member.role > maxDemotableRole
    }
    
    var maxDemotableRole: RoomRole {
        switch mode {
        case .owner:
            return .owner
        case .administrator:
            switch ownRole {
            case .owner:
                return .administrator
            case .creator:
                return .owner
            default:
                return .moderator
            }
        case .moderator:
            return .moderator
        default:
            return .user
        }
    }
}

struct RoomChangeRolesScreenViewStateBindings {
    var searchQuery = ""
    /// Information about the currently displayed alert.
    var alertInfo: AlertInfo<RoomChangeRolesScreenAlertType>?
}

enum RoomChangeRolesScreenAlertType {
    /// A warning that a particular promotion can't be undone.
    case promotionWarning
    /// A warning that ownership transfer is final when the room is left.
    case transferOwnershipWarning
    /// A confirmation that the user would like to discard any unsaved changes.
    case discardChanges
    /// The generic error message.
    case error
}

enum RoomChangeRolesScreenViewAction {
    /// Promote/Demote the specified member, toggling their role between user and this screen's role.
    case toggleMember(RoomMemberDetails)
    /// Demote the specified member to a regular user.
    case demoteMember(RoomMemberDetails)
    /// Save all the changes that the user has made.
    case save
    /// Discard any changes and hide the screen.
    case cancel
}

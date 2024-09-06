//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Collections
import Foundation

enum RoomChangeRolesScreenViewModelAction {
    case complete
}

struct RoomChangeRolesScreenViewState: BindableState {
    /// The screen's current mode (which role we are promoting/demoting users to/from.
    let mode: RoomMemberDetails.Role
    /// All of the room's members who are currently admins.
    var administrators: [RoomMemberDetails]
    /// All of the room's members who are currently moderators.
    var moderators: [RoomMemberDetails]
    /// All of the room's members who are currently neither an admin or moderator.
    var users: [RoomMemberDetails]
    
    var bindings: RoomChangeRolesScreenViewStateBindings
    
    /// The members selected for promotion to the current role.
    var membersToPromote: Set<RoomMemberDetails> = []
    /// The member selected for demotion back to a regular user.
    var membersToDemote: Set<RoomMemberDetails> = []
    
    /// The last member added to the carousel at the top of the screen.
    var lastPromotedMember: RoomMemberDetails?
    
    /// The screen's title.
    var title: String {
        switch mode {
        case .administrator:
            L10n.screenRoomChangeRoleAdministratorsTitle
        case .moderator:
            L10n.screenRoomChangeRoleModeratorsTitle
        case .user:
            "" // The screen can't be configured with this role.
        }
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
        administrators.filter(isMemberSelected) + moderators.filter(isMemberSelected) + users.filter(isMemberSelected)
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
        return member.role == mode || membersToPromote.contains(member)
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

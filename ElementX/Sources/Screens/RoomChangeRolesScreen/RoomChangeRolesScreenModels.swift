//
// Copyright 2022 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Collections
import Foundation

enum RoomChangeRolesScreenViewModelAction {
    case done
}

struct RoomChangeRolesScreenViewState: BindableState {
    /// The screen's current mode (which role we are promoting/demoting users to/from.
    let mode: RoomMemberDetails.Role
    /// All of the room's members.
    var members: [RoomMemberDetails]
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
    
    /// The visible members in the screen (after searching).
    var visibleMembers: [RoomMemberDetails] {
        guard !bindings.searchQuery.isEmpty else { return members }
        
        return members.filter { member in
            member.name?.localizedStandardContains(bindings.searchQuery) == true
                || member.id.localizedStandardContains(bindings.searchQuery)
        }
    }
    
    /// All of the members who will gain/keep this screen's role after saving any changes.
    var membersWithRole: [RoomMemberDetails] {
        members.filter(isMemberSelected)
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
    var alertInfo: AlertInfo<RoomChangePermissionsScreenAlertType>?
}

enum RoomChangeRolesScreenAlertType {
    /// The generic error message.
    case generic
}

enum RoomChangeRolesScreenViewAction {
    /// Promote/Demote the specified member, toggling their role between user and this screen's role.
    case toggleMember(RoomMemberDetails)
    /// Demote the specified member to a regular user.
    case demoteMember(RoomMemberDetails)
    /// Save all the changes that the user has made.
    case save
}

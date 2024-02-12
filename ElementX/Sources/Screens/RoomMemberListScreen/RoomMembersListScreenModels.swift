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

import Foundation

enum RoomMembersListScreenViewModelAction {
    case selectMember(_ member: RoomMemberProxyProtocol)
    case invite
}

/// The different modes that the screen can be in.
enum RoomMembersListScreenMode {
    /// The screen is showing invited and joined members.
    case members
    /// The screen is showing banned members (to mods/admins)
    case banned
}

struct RoomMembersListScreenViewState: BindableState {
    private var joinedMembers: [RoomMemberDetails]
    private var invitedMembers: [RoomMemberDetails]
    private var bannedMembers: [RoomMemberDetails]
    
    let joinedMembersCount: Int
    var bannedMembersCount: Int { bannedMembers.count }
    
    var canInviteUsers = false
    var canBanUsers = false
    
    var bindings: RoomMembersListScreenViewStateBindings
    
    init(joinedMembersCount: Int,
         joinedMembers: [RoomMemberDetails] = [],
         invitedMembers: [RoomMemberDetails] = [],
         bannedMembers: [RoomMemberDetails] = [],
         bindings: RoomMembersListScreenViewStateBindings) {
        self.joinedMembersCount = joinedMembersCount
        self.joinedMembers = joinedMembers
        self.invitedMembers = invitedMembers
        self.bannedMembers = bannedMembers
        self.bindings = bindings
    }

    var visibleJoinedMembers: [RoomMemberDetails] {
        joinedMembers
            .filter { $0.matches(searchQuery: bindings.searchQuery) }
    }
    
    var visibleInvitedMembers: [RoomMemberDetails] {
        invitedMembers
            .filter { $0.matches(searchQuery: bindings.searchQuery) }
    }
    
    var visibleBannedMembers: [RoomMemberDetails] {
        bannedMembers
            .filter { $0.matches(searchQuery: bindings.searchQuery) }
    }
}

struct RoomMembersListScreenViewStateBindings {
    var searchQuery = ""
    /// The current mode the screen is in.
    var mode: RoomMembersListScreenMode = .members

    /// Information describing the currently displayed alert.
    var alertInfo: AlertInfo<RoomDetailsScreenErrorType>?
}

enum RoomMembersListScreenViewAction {
    case selectMember(id: String)
    case invite
}

private extension RoomMemberDetails {
    func matches(searchQuery: String) -> Bool {
        guard !searchQuery.isEmpty else {
            return true
        }
        
        return id.localizedCaseInsensitiveContains(searchQuery) || name?.localizedCaseInsensitiveContains(searchQuery) ?? false
    }
}

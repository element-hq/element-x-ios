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

struct RoomMembersListScreenViewState: BindableState {
    private var joinedMembers: [RoomMemberDetails]
    private var invitedMembers: [RoomMemberDetails]
    
    let joinedMembersCount: UInt
    var canInviteUsers = false
    var bindings: RoomMembersListScreenViewStateBindings
    
    init(joinedMembersCount: UInt,
         joinedMembers: [RoomMemberDetails] = [],
         invitedMembers: [RoomMemberDetails] = [],
         bindings: RoomMembersListScreenViewStateBindings = .init()) {
        self.joinedMembersCount = joinedMembersCount
        self.joinedMembers = joinedMembers
        self.invitedMembers = invitedMembers
        self.bindings = bindings
    }

    var visibleJoinedMembers: [RoomMemberDetails] {
        joinedMembers.lazy
            .filter { member in
                member.matches(searchQuery: bindings.searchQuery)
            }
    }
    
    var visibleInvitedMembers: [RoomMemberDetails] {
        invitedMembers.lazy
            .filter { member in
                member.matches(searchQuery: bindings.searchQuery)
            }
    }
}

struct RoomMembersListScreenViewStateBindings {
    var searchQuery = ""

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

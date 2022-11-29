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

enum RoomMembersViewModelAction {
    case cancel
}

struct RoomMembersViewState: BindableState {
    var members: [RoomDetailsMember]

    var bindings: RoomMembersViewStateBindings

    var visibleMembers: [RoomDetailsMember] {
        if bindings.searchQuery.isEmpty {
            return members
        }

        return members.lazy.filter { member in
            member.id.localizedCaseInsensitiveContains(bindings.searchQuery) ||
            member.name?.localizedCaseInsensitiveContains(bindings.searchQuery) ?? false
        }
    }
}

struct RoomMembersViewStateBindings {
    var searchQuery = ""

    /// Information describing the currently displayed alert.
    var alertInfo: AlertInfo<RoomDetailsErrorType>?
}

enum RoomMembersViewAction {
    case selectMember(id: String)
    case loadMemberData(id: String)
    case cancel
}

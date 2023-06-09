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
import MatrixRustSDK

enum InviteUsersScreenErrorType: Error {
    case unknown
}

enum InviteUsersScreenViewModelAction {
    case proceed
    case invite(users: [String])
    case toggleUser(UserProfileProxy)
}

enum InviteUsersScreenRoomType {
    case draft
    case room(roomProxy: RoomProxyProtocol)
}

struct InviteUsersScreenViewState: BindableState {
    var bindings = InviteUsersScreenViewStateBindings()
    
    var usersSection: UserDiscoverySection = .init(type: .suggestions, users: [])
    
    var selectedUsers: [UserProfileProxy] = []
    var membershipState: [String: MembershipState] = .init()
    
    var isSearching: Bool {
        !bindings.searchQuery.isEmpty
    }
    
    var hasEmptySearchResults: Bool {
        isSearching && usersSection.type == .searchResult && usersSection.users.isEmpty
    }
    
    var scrollToLastID: String?
    
    func isUserSelected(_ user: UserProfileProxy) -> Bool {
        isUserDisabled(user) || selectedUsers.contains { $0.userID == user.userID }
    }
    
    func isUserDisabled(_ user: UserProfileProxy) -> Bool {
        let membershipState = membershipState(user)
        return membershipState == .invite || membershipState == .join
    }
    
    func membershipState(_ user: UserProfileProxy) -> MembershipState? {
        membershipState[user.userID]
    }
    
    let isCreatingRoom: Bool
    
    var actionText: String {
        if isCreatingRoom {
            return selectedUsers.isEmpty ? L10n.actionSkip : L10n.actionNext
        } else {
            return L10n.actionInvite
        }
    }
    
    var isActionDisabled: Bool {
        isCreatingRoom ? false : selectedUsers.isEmpty
    }
}

struct InviteUsersScreenViewStateBindings {
    var searchQuery = ""
    
    /// Information describing the currently displayed alert.
    var alertInfo: AlertInfo<InviteUsersScreenErrorType>?
}

enum InviteUsersScreenViewAction {
    case proceed
    case toggleUser(UserProfileProxy)
}

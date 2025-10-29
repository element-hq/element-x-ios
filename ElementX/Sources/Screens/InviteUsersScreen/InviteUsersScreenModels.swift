//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRustSDK

// periphery:ignore - for generic conformance
enum InviteUsersScreenErrorType: Error {
    case unknown
}

enum InviteUsersScreenViewModelAction {
    case dismiss
}

enum InviteUsersScreenRoomType {
    case draft
    case room(roomProxy: JoinedRoomProxyProtocol)
}

struct InviteUsersScreenViewState: BindableState {
    var bindings = InviteUsersScreenViewStateBindings()
    
    var usersSection: UserDiscoverySection = .init(type: .suggestions, users: [])
    
    var selectedUsers: [UserProfileProxy] = []
    var membershipState: [String: MembershipState] = .init()
    
    var isSearching = false
    
    var hasEmptySearchResults: Bool {
        !isSearching && usersSection.type == .searchResult && usersSection.users.isEmpty
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
        if isCreatingRoom, selectedUsers.isEmpty {
            L10n.actionSkip
        } else {
            L10n.actionInvite
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
    case cancel
    case proceed
    case toggleUser(UserProfileProxy)
}

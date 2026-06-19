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
    case openRoom(roomID: String)
}

enum InviteUsersScreenRoomType {
    case draft(mandatoryInvitees: [UserProfileProxy])
    case existingRoom(roomProxy: JoinedRoomProxyProtocol)
}

struct InviteUsersScreenViewState: BindableState {
    var bindings = InviteUsersScreenViewStateBindings()
    
    var usersSection: UserDiscoverySection = .init(type: .suggestions, users: [])
    
    var selectedUsers: [UserProfileProxy] = []
    var mandatoryInvitees: [UserProfileProxy] = []
    var membershipState: [String: MembershipState] = .init()
    var usersToConfirm: [UserProfileProxy] = []
    
    var isSearching = false
    
    var hasEmptySearchResults: Bool {
        !isSearching && usersSection.type == .searchResult && usersSection.users.isEmpty
    }
    
    var hasInvitableSelectedUsers: Bool {
        selectedUsers.contains { !isInviteeMandatory($0) }
    }
    
    func isUserSelected(_ user: UserProfileProxy) -> Bool {
        isUserDisabled(user) || selectedUsers.contains { $0.userID == user.userID }
    }
    
    func isUserDisabled(_ user: UserProfileProxy) -> Bool {
        if isInviteeMandatory(user) {
            return true
        }
        let membershipState = membershipState(user)
        return membershipState == .invite || membershipState == .join
    }
    
    func isInviteeMandatory(_ user: UserProfileProxy) -> Bool {
        mandatoryInvitees.contains { $0.userID == user.userID }
    }
    
    func membershipState(_ user: UserProfileProxy) -> MembershipState? {
        membershipState[user.userID]
    }
    
    let isSkippable: Bool
}

struct InviteUsersScreenViewStateBindings {
    var searchQuery = ""
    var selectedUsersPosition: String?
    
    /// Whether we are showing the confirmation dialog.
    var presentConfirmationDialog = false
    
    /// Information describing the currently displayed alert.
    var alertInfo: AlertInfo<InviteUsersScreenErrorType>?
}

enum InviteUsersScreenViewAction {
    case cancel
    case proceed
    case removeUnknownUsers
    case confirmUnknownUsers
    case toggleUser(UserProfileProxy)
}

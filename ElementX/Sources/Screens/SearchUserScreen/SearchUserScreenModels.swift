//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

enum SearchUserScreenViewModelAction: Equatable {
    case close
    case selectUser(UserProfileProxy)
}

struct SearchUserScreenViewState: BindableState {
    var bindings = SearchUserScreenViewStateBindings()
    var usersSection: UserDiscoverySection = .init(type: .suggestions, users: [])

    var isSearching: Bool {
        !bindings.searchQuery.isEmpty
    }
    
    var hasEmptySearchResults: Bool {
        isSearching && usersSection.type == .searchResult && usersSection.users.isEmpty
    }
}

struct SearchUserScreenViewStateBindings {
    var searchQuery = ""
    
    var selectedUserToInvite: UserProfileProxy?
}

enum SearchUserScreenViewAction {
    case close
    case selectUser(UserProfileProxy)
}

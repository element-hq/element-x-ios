//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

enum StartChatScreenErrorType: Error {
    case failedCreatingRoom
    case unknown
}

enum StartChatScreenViewModelAction {
    case close
    case createRoom
    case openRoom(withIdentifier: String)
}

struct StartChatScreenViewState: BindableState {
    let userID: String
    var bindings = StartChatScreenViewStateBindings()
    var usersSection: UserDiscoverySection = .init(type: .suggestions, users: [])

    var isSearching: Bool {
        !bindings.searchQuery.isEmpty
    }
    
    var hasEmptySearchResults: Bool {
        isSearching && usersSection.type == .searchResult && usersSection.users.isEmpty
    }
}

struct StartChatScreenViewStateBindings {
    var searchQuery = ""
    
    /// Information describing the currently displayed alert.
    var alertInfo: AlertInfo<StartChatScreenErrorType>?
}

enum StartChatScreenViewAction {
    case close
    case createRoom
    case selectUser(UserProfileProxy)
}

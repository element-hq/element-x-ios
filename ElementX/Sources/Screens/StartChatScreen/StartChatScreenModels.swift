//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

enum StartChatScreenErrorType: Error {
    case failedCreatingRoom
    case unknown
}

enum StartChatScreenViewModelAction: Equatable {
    case close
    case createRoom
    case showRoom(roomID: String)
    case openRoomDirectorySearch
}

struct StartChatScreenViewState: BindableState {
    let userID: String
    var bindings = StartChatScreenViewStateBindings()
    var usersSection: UserDiscoverySection = .init(type: .suggestions, users: [])
    var isRoomDirectoryEnabled = false

    var isSearching: Bool {
        !bindings.searchQuery.isEmpty
    }
    
    var hasEmptySearchResults: Bool {
        isSearching && usersSection.type == .searchResult && usersSection.users.isEmpty
    }
    
    var joinByAddressState: JoinByAddressState = .example
}

struct StartChatScreenViewStateBindings {
    var searchQuery = ""
    var roomAddress = ""
    
    /// Information describing the currently displayed alert.
    var alertInfo: AlertInfo<StartChatScreenErrorType>?
    
    var selectedUserToInvite: UserProfileProxy?
    var isJoinRoomByAddressSheetPresented = false
}

enum StartChatScreenViewAction {
    case close
    case createRoom
    case createDM(user: UserProfileProxy)
    case selectUser(UserProfileProxy)
    case joinRoomByAddress
    case openRoomDirectorySearch
}

enum JoinByAddressState: Equatable {
    case example
    case invalidAddress
    case addressNotFound
    case addressFound(address: String, roomID: String)
}

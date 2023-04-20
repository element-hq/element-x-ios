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

enum StartChatErrorType: Error {
    case failedSearchingUsers
    case failedRetrievingDirectRoom
    case failedCreatingRoom
}

enum StartChatViewModelAction {
    case close
    case createRoom
    case openRoom(withIdentifier: String)
}

struct StartChatViewState: BindableState {
    var bindings = StartChatScreenViewStateBindings()
    var usersSection: SearchUsersSection = .init(type: .suggestions, users: [])

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
    var alertInfo: AlertInfo<StartChatErrorType>?
}

enum StartChatViewAction {
    case close
    case createRoom
    case inviteFriends
    case selectUser(UserProfile)
}

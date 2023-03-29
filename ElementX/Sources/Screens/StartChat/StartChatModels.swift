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

enum StartChatViewModelAction {
    case close
    case createRoom
    case openRoom(withIdentifier: String)
}

struct StartChatViewState: BindableState {
    var bindings = StartChatScreenViewStateBindings()
    var usersSection: StartChatUsersSection = .init(type: .suggestions, users: [])
}

extension StartChatViewState {
    var isSearching: Bool {
        !bindings.searchQuery.isEmpty
    }
    
    var hasEmptySearchResults: Bool {
        isSearching && usersSection.type == .searchResult && usersSection.users.isEmpty
    }
}

enum StartChatUserSectionType: Equatable {
    case searchResult
    case suggestions
}

extension StartChatUserSectionType {
    var title: String? {
        switch self {
        case .searchResult:
            return nil
        case .suggestions:
            return L10n.commonSuggestions
        }
    }
}

struct StartChatUsersSection {
    let type: StartChatUserSectionType
    let users: [UserProfile]
}

struct StartChatScreenViewStateBindings {
    var searchQuery = ""
    
    /// Information describing the currently displayed alert.
    var alertInfo: AlertInfo<ClientProxyError>?
}

enum StartChatViewAction {
    case close
    case createRoom
    case inviteFriends
    case selectUser(UserProfile)
}

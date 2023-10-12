//
// Copyright 2023 New Vector Ltd
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

import WysiwygComposer

enum SuggestionItem: Identifiable, Equatable {
    case user(item: MentionSuggestionItem)
    case allUsers(item: MentionSuggestionItem)
    
    var id: String {
        switch self {
        case .user(let user):
            return user.id
        case .allUsers:
            return PillConstants.atRoom
        }
    }
    
    var name: String? {
        switch self {
        case .user(let user):
            return user.displayName
        case .allUsers:
            return PillConstants.everyone
        }
    }
}

struct MentionSuggestionItem: Identifiable, Equatable {
    let id: String
    let displayName: String?
    let avatarURL: URL?
    
    static func allUsersMention(roomAvatar: URL?) -> Self {
        MentionSuggestionItem(id: PillConstants.atRoom, displayName: PillConstants.everyone, avatarURL: roomAvatar)
    }
}

extension WysiwygComposer.SuggestionPattern {
    var toElementPattern: SuggestionPattern? {
        switch key {
        case .at:
            return SuggestionPattern(type: .user, text: text)
        // Not yet supported
        default:
            return nil
        }
    }
}

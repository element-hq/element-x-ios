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

enum EmojiPickerScreenViewModelAction {
    case emojiSelected(emoji: String)
    case dismiss
}

struct EmojiPickerScreenViewState: BindableState {
    var categories: [EmojiPickerEmojiCategoryViewData]
}

enum EmojiPickerScreenViewAction {
    case search(searchString: String)
    case emojiTapped(emoji: EmojiPickerEmojiViewData)
    case dismiss
}

struct EmojiPickerEmojiCategoryViewData: Identifiable {
    let id: String
    let emojis: [EmojiPickerEmojiViewData]
    
    var name: String {
        switch id {
        case "people":
            return L10n.emojiPickerCategoryPeople
        case "nature":
            return L10n.emojiPickerCategoryNature
        case "foods":
            return L10n.emojiPickerCategoryFoods
        case "activity":
            return L10n.emojiPickerCategoryActivity
        case "places":
            return L10n.emojiPickerCategoryPlaces
        case "objects":
            return L10n.emojiPickerCategoryObjects
        case "symbols":
            return L10n.emojiPickerCategorySymbols
        case "flags":
            return L10n.emojiPickerCategoryFlags
        default:
            MXLog.failure("Missing translation for emoji category with id \(id)")
            return ""
        }
    }
}

struct EmojiPickerEmojiViewData: Identifiable {
    var id: String
    let value: String
}

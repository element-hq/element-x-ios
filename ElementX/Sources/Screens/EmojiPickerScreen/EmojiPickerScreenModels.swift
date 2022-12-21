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
            return ElementL10n.emojiPickerPeopleCategory
        case "nature":
            return ElementL10n.emojiPickerNatureCategory
        case "foods":
            return ElementL10n.emojiPickerFoodsCategory
        case "activity":
            return ElementL10n.emojiPickerActivityCategory
        case "places":
            return ElementL10n.emojiPickerPlacesCategory
        case "objects":
            return ElementL10n.emojiPickerObjectsCategory
        case "symbols":
            return ElementL10n.emojiPickerSymbolsCategory
        case "flags":
            return ElementL10n.emojiPickerFlagsCategory
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

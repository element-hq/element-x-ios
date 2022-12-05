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

enum EmojiPickerScreenViewModelAction { }

struct EmojiPickerScreenViewState: BindableState {
    var categories: [EmojiPickerEmojiCategoryViewData]
}

enum EmojiPickerScreenViewAction {
    case search(searchString: String)
    case emojiSelected(emoji: EmojiPickerEmojiViewData)
}

struct EmojiPickerEmojiCategoryViewData: Identifiable {
    let id: String
    let emojis: [EmojiPickerEmojiViewData]
    
    var name: String {
        let categoryNameLocalizationKey = "emoji_picker_\(id)_category"
        return ElementL10n.tr("Localizable", categoryNameLocalizationKey)
    }
}

struct EmojiPickerEmojiViewData: Identifiable {
    var id: String
    let value: String
}

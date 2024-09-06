//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
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

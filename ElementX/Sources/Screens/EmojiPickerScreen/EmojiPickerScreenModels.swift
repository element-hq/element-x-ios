//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

typealias EmojiPickerScreenContinuation = AsyncStream<EmojiPickerItem>.Continuation
enum EmojiPickerScreenMode { case reaction, userStatus }

enum EmojiPickerScreenViewModelAction {
    case dismiss
}

struct EmojiPickerScreenViewState: BindableState {
    let mode: EmojiPickerScreenMode
    var categories: [EmojiPickerEmojiCategoryViewData]
    var selectedEmojis: Set<String>
    
    var title: String {
        switch mode {
        case .reaction: L10n.commonReactions
        case .userStatus: L10n.a11yCustomEmoji
        }
    }
}

enum EmojiPickerScreenViewAction {
    case search(searchString: String)
    case emojiTapped(emoji: EmojiPickerEmojiViewData)
    case dismiss
}

struct EmojiPickerEmojiCategoryViewData: Identifiable {
    let id: String
    let emojis: [EmojiPickerEmojiViewData]
    /// The name of the category when it isn't one of the built-in ones (e.g. a custom image pack).
    var customName: String?
    
    var name: String {
        if let customName {
            return customName
        }
        
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
        case EmojiCategory.frequentlyUsedCategoryIdentifier:
            return L10n.commonFrequentlyUsed
        default:
            MXLog.failure("Missing translation for emoji category with id \(id)")
            return ""
        }
    }
}

struct EmojiPickerEmojiViewData: Identifiable {
    var id: String
    let item: EmojiPickerItem
}

enum EmojiPickerItem: Hashable {
    case emoji(String)
    case customImage(ImagePack.Image)
    
    /// The reaction key: the emoji itself or the `mxc://` URL of the custom image.
    var key: String {
        switch self {
        case .emoji(let emoji): emoji
        case .customImage(let image): image.mediaSource.url.absoluteString
        }
    }
}

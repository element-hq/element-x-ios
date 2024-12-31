//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

struct EmojiItem: Equatable, Identifiable {
    var id: String {
        label
    }

    let label: String
    let unicode: String
    let keywords: [String]
    let shortcodes: [String]
}

struct EmojiCategory: Equatable, Identifiable {
    static let frequentlyUsedCategoryIdentifier = "io.element.elementx.frequently_used"
    
    let id: String
    let emojis: [EmojiItem]
}

enum EmojiProviderState {
    case notLoaded
    case inProgress(Task<[EmojiCategory], Never>)
    case loaded([EmojiCategory])
}

struct FrequentlyUsedEmoji: Codable, Hashable {
    let count: UInt
    let key: String
    
    static func == (lhs: FrequentlyUsedEmoji, rhs: FrequentlyUsedEmoji) -> Bool {
        lhs.key == rhs.key
    }
}

@MainActor
protocol EmojiProviderProtocol {
    var state: EmojiProviderState { get }
    
    func categories(searchString: String?) async -> [EmojiCategory]
    
    func frequentlyUsedSystemEmojis() -> [String]
    func markEmojiAsFrequentlyUsed(_ emoji: String)
}

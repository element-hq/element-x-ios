//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Emojibase
import Foundation
import OrderedCollections

class EmojiProvider: EmojiProviderProtocol {
    private let loader: EmojiLoaderProtocol
    private let appSettings: AppSettings
    
    private(set) var state: EmojiProviderState = .notLoaded
    
    init(loader: EmojiLoaderProtocol = EmojibaseDatasource(), appSettings: AppSettings) {
        self.loader = loader
        self.appSettings = appSettings
        
        Task {
            await loadIfNeeded()
        }
    }
    
    func categories(searchString: String? = nil) async -> [EmojiCategory] {
        var emojiCategories = await loadIfNeeded()
        
        let allEmojis = emojiCategories.reduce([]) { partialResult, category in
            partialResult + category.emojis
        }
        
        // Map frequently used system unicode emojis to our emoji provider ones
        let frequentlyUsedEmojis = frequentlyUsedSystemEmojis().prefix(20)
        let emojis = allEmojis.filter { frequentlyUsedEmojis.contains($0.unicode) }
        
        if !emojis.isEmpty {
            emojiCategories.insert(.init(id: EmojiCategory.frequentlyUsedCategoryIdentifier, emojis: emojis), at: 0)
        }
        
        if let searchString, searchString.isEmpty == false {
            return search(searchString: searchString, emojiCategories: emojiCategories)
        } else {
            return emojiCategories
        }
    }
    
    func frequentlyUsedSystemEmojis() -> [String] {
        guard appSettings.frequentEmojisEnabled, !ProcessInfo.processInfo.isiOSAppOnMac else {
            return []
        }
        
        guard let preferences = UserDefaults(suiteName: "com.apple.EmojiPreferences"),
              let defaults = preferences.dictionary(forKey: "EMFDefaultsKey"),
              let recents = defaults["EMFRecentsKey"] as? [String]
        else {
            return []
        }
        
        return recents
    }
    
    func markEmojiAsFrequentlyUsed(_ emoji: String) {
        guard appSettings.frequentEmojisEnabled else {
            return
        }
        
        guard let preferences = UserDefaults(suiteName: "com.apple.EmojiPreferences"),
              let defaults = preferences.dictionary(forKey: "EMFDefaultsKey"),
              let recents = defaults["EMFRecentsKey"] as? [String] else {
            return
        }
        
        var uniqueOrderedRecents = OrderedSet(recents)
        uniqueOrderedRecents.insert(emoji, at: 0)
        
        preferences.setValue(["EMFRecentsKey": Array(uniqueOrderedRecents)], forKey: "EMFDefaultsKey")
    }
    
    // MARK: - Private
    
    private func search(searchString: String, emojiCategories: [EmojiCategory]) -> [EmojiCategory] {
        emojiCategories.compactMap { category in
            let emojis = category.emojis.filter { emoji in
                let searchArray = [emoji.label + emoji.unicode] + emoji.shortcodes + emoji.keywords
                return searchArray.description.range(of: searchString, options: .caseInsensitive) != nil
            }
            return emojis.isEmpty ? nil : EmojiCategory(id: category.id, emojis: emojis)
        }
    }
    
    private func loadIfNeeded() async -> [EmojiCategory] {
        switch state {
        case .notLoaded:
            let task = Task {
                await loader.load()
            }
            state = .inProgress(task)
            let categories = await task.value
            state = .loaded(categories)
            return categories
        case .loaded(let categories):
            return categories
        case .inProgress(let task):
            return await task.value
        }
    }
}

extension EmojibaseDatasource: EmojiLoaderProtocol {
    func load() async -> [EmojiCategory] {
        do {
            let store: EmojibaseStore = try await load()
            return EmojibaseCategory.allCases.map { category in
                let emojis = store.categories[category.rawValue] ?? []
                return EmojiCategory(id: category.rawValue, emojis: emojis.compactMap(EmojiItem.init(from:)))
            }
        } catch {
            MXLog.error("Failed retrieving emojis from the emojibase datasource: \(error)")
        }
        return []
    }
}

extension EmojiItem {
    init?(from emojibase: Emoji) {
        unicode = emojibase.unicode
        label = emojibase.label
        shortcodes = emojibase.shortcodes
        keywords = emojibase.tags ?? []
    }
}

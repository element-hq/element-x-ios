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

import Emojibase
import Foundation

@MainActor
protocol EmojiProviderProtocol {
    func getCategories(searchString: String?) async -> [EmojiCategory]
}

private enum EmojiProviderState {
    case notLoaded
    case inProgress(Task<[EmojiCategory], Never>)
    case loaded([EmojiCategory])
}

class EmojiProvider: EmojiProviderProtocol {
    private let loader: EmojiLoaderProtocol
    private var state: EmojiProviderState = .notLoaded
    
    init(loader: EmojiLoaderProtocol = EmojibaseDatasource()) {
        self.loader = loader
        Task {
            await loadIfNeeded()
        }
    }
    
    func getCategories(searchString: String? = nil) async -> [EmojiCategory] {
        let emojiCategories = await loadIfNeeded()
        if let searchString, searchString.isEmpty == false {
            return search(searchString: searchString, emojiCategories: emojiCategories)
        } else {
            return emojiCategories
        }
    }
    
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
        skins = emojibase.skins?.map(\.unicode) ?? []
    }
}

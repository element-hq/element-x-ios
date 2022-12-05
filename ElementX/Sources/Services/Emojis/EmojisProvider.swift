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

@MainActor
protocol EmojisProviderProtocol {
    func getCategories(searchString: String?) async -> [EmojiCategory]
}

private enum EmojisProviderState {
    case notLoaded
    case inProgress(Task<[EmojiCategory], Never>)
    case loaded([EmojiCategory])
}

class EmojisProvider: EmojisProviderProtocol {
    private let loader: EmojisLoaderProtocol
    private var state: EmojisProviderState = .notLoaded
    
    init(loader: EmojisLoaderProtocol = EmojiMartJSONLoader()) {
        self.loader = loader
        Task {
            await loadIfNeeded()
        }
    }
    
    func getCategories(searchString: String? = nil) async -> [EmojiCategory] {
        let emojiCategories = await loadIfNeeded()
        if let searchString = searchString {
            return search(searchString: searchString, emojiCategories: emojiCategories)
        } else {
            return emojiCategories
        }
    }
    
    private func search(searchString: String, emojiCategories: [EmojiCategory]) -> [EmojiCategory] {
        emojiCategories.compactMap { category in
            let emojis = category.emojis.filter { emoji in
                let searchArray = [emoji.id, emoji.name] + emoji.keywords
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

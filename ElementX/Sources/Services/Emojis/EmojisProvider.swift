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
class EmojisProvider {
    private let loader: EmojisLoaderProtocol
    private static var emojiCategories = [EmojiCategory]()
    
    init(loader: EmojisLoaderProtocol = EmojiMartJSONLoader()) {
        self.loader = loader
    }
    
    func search(searchString: String) async -> [EmojiCategory] {
        guard !searchString.isEmpty else {
            return Self.emojiCategories
        }
     
        return Self.emojiCategories.compactMap { category in
            let emojis = category.emojis.filter { emoji in
                let searchArray = [emoji.id, emoji.name] + emoji.keywords
                return searchArray.description.containsIgnoringCase(string: searchString)
            }
            return emojis.isEmpty ? nil : EmojiCategory(id: category.id, emojis: emojis)
        }
    }
    
    func load() async -> [EmojiCategory] {
        guard Self.emojiCategories.isEmpty else {
            return Self.emojiCategories
        }
        Self.emojiCategories = await loader.load()
        return Self.emojiCategories
    }
}

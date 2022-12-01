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

private enum EmojiMartJSONLoaderError: Error {
    case fileNotFound
}

class EmojiMartJSONLoader: EmojisLoaderProtocol {
    /// Emoji data coming from https://github.com/missive/emoji-mart/blob/main/packages/emoji-mart-data/sets/14/apple.json
    private let jsonFilename = "apple_emojis_data"
    
    func load() async -> [EmojiCategory] {
        do {
            let data = try await loadJSONData()
            let store = try await decodeJSONData(data: data)
            return emojiCategories(from: store)
        } catch {
            MXLog.error("Couldn't parse emoji json")
            return []
        }
    }
    
    private func loadJSONData() async throws -> Data {
        guard let jsonDataURL = Bundle.main.url(forResource: jsonFilename, withExtension: "json") else {
            throw EmojiMartJSONLoaderError.fileNotFound
        }
        return try Data(contentsOf: jsonDataURL)
    }
    
    private func decodeJSONData(data: Data) async throws -> EmojiMartStore {
        try JSONDecoder().decode(EmojiMartStore.self, from: data)
    }
    
    private func emojiCategories(from emojiMartStore: EmojiMartStore) -> [EmojiCategory] {
        emojiMartStore.categories.map { emojiMartCategory -> EmojiCategory in
            let emojiItems = emojiMartCategory.emojis.compactMap { emoji -> EmojiItem? in
                guard let emojiMartEmoji = emojiMartStore.emojis.first(where: { $0.id == emoji }) else {
                    return nil
                }
                return EmojiItem(from: emojiMartEmoji)
            }
            return EmojiCategory(id: emojiMartCategory.id, emojis: emojiItems)
        }
    }
}

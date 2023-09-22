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

import XCTest

@testable import ElementX

final class EmojiProviderTests: XCTestCase {
    func testWhenEmojisLoadedCategoriesAreLoadedFromLoader() async throws {
        let item = EmojiItem(label: "test", unicode: "test", keywords: ["1", "2"], shortcodes: ["1", "2"], skins: ["🙂"])
        let category = EmojiCategory(id: "test", emojis: [item])
        
        let emojiLoaderMock = EmojiLoaderMock()
        emojiLoaderMock.categories = [category]
        
        let emojiProvider = await EmojiProvider(loader: emojiLoaderMock)
        
        let categories = await emojiProvider.getCategories()
        XCTAssertEqual(emojiLoaderMock.categories, categories)
    }

    func testWhenEmojisLoadedAndSearchStringEmptyAllCategoriesReturned() async throws {
        let item = EmojiItem(label: "test", unicode: "test", keywords: ["1", "2"], shortcodes: ["1", "2"], skins: ["🙂"])
        let category = EmojiCategory(id: "test", emojis: [item])
        
        let emojiLoaderMock = EmojiLoaderMock()
        emojiLoaderMock.categories = [category]
        
        let emojiProvider = await EmojiProvider(loader: emojiLoaderMock)
        
        let categories = await emojiProvider.getCategories(searchString: "")
        XCTAssertEqual(emojiLoaderMock.categories, categories)
    }

    func testWhenEmojisLoadedSecondTimeCachedValuesAreUsed() async throws {
        let item = EmojiItem(label: "test", unicode: "test", keywords: ["1", "2"], shortcodes: ["1", "2"], skins: ["🙂"])
        let item2 = EmojiItem(label: "test2", unicode: "test2", keywords: ["3", "4"], shortcodes: ["3", "4"], skins: ["🙂"])
        let categoriesForFirstLoad = [EmojiCategory(id: "test",
                                                    emojis: [item])]
        let categoriesForSecondLoad = [EmojiCategory(id: "test2",
                                                     emojis: [item2])]
        
        let emojiLoaderMock = EmojiLoaderMock()
        emojiLoaderMock.categories = categoriesForFirstLoad
        
        let emojiProvider = await EmojiProvider(loader: emojiLoaderMock)
        
        _ = await emojiProvider.getCategories()
        emojiLoaderMock.categories = categoriesForSecondLoad
        
        let categories = await emojiProvider.getCategories()
        XCTAssertEqual(categories, categoriesForFirstLoad)
    }
    
    func testWhenEmojisSearchedCorrectNumberOfCategoriesReturned() async throws {
        let searchString = "smile"
        var categories = [EmojiCategory]()
        let item0WithSearchString = EmojiItem(label: "emoji0", unicode: "\(searchString)_123", keywords: ["key1", "key1"], shortcodes: ["key1", "key1"], skins: ["🙂"])
        let item1WithSearchString = EmojiItem(label: searchString, unicode: "emoji1", keywords: ["key1", "key1"], shortcodes: ["key1", "key1"], skins: ["🙂"])
        let item2WithSearchString = EmojiItem(label: "emoji_2", unicode: "emoji_2", keywords: ["key1", "\(searchString)_123"], shortcodes: ["key1", "key2"], skins: ["🙂"])
        let item3WithSearchString = EmojiItem(label: "emoji_2", unicode: "emoji_2", keywords: ["key1", "key1"], shortcodes: ["key1", "\(searchString)_123"], skins: ["🙂"])
        let item4WithoutSearchString = EmojiItem(label: "emoji_3", unicode: "emoji_3", keywords: ["key1", "key1"], shortcodes: ["key1", "key1"], skins: ["🙂"])
        let item5WithSearchString = EmojiItem(label: "emoji0", unicode: "\(searchString)_123", keywords: ["key1", "key1"], shortcodes: ["key1", "key1"], skins: ["🙂"])
        categories.append(EmojiCategory(id: "test",
                                        emojis: [item0WithSearchString,
                                                 item1WithSearchString,
                                                 item2WithSearchString,
                                                 item3WithSearchString,
                                                 item4WithoutSearchString]))
        categories.append(EmojiCategory(id: "test",
                                        emojis: [item5WithSearchString]))
        
        let emojiLoaderMock = EmojiLoaderMock()
        emojiLoaderMock.categories = categories
        
        let emojiProvider = await EmojiProvider(loader: emojiLoaderMock)
        
        _ = await emojiProvider.getCategories()
        let result = await emojiProvider.getCategories(searchString: searchString)
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result.first?.emojis.count, 4)
    }
}

private class EmojiLoaderMock: EmojiLoaderProtocol {
    var categories = [ElementX.EmojiCategory]()
    func load() async -> [ElementX.EmojiCategory] {
        categories
    }
}

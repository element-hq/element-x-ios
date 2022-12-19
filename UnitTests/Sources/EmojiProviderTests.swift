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
    var sut: EmojiProvider!
    private var emojiLoaderMock: EmojiLoaderMock!
    
    @MainActor override func setUp() {
        emojiLoaderMock = EmojiLoaderMock()
        sut = EmojiProvider(loader: emojiLoaderMock)
    }
    
    func test_whenEmojisLoaded_categoriesAreLoadedFromLoader() async throws {
        let item = EmojiItem(id: "test", name: "test", keywords: ["1", "2"], skins: ["🙂"])
        let category = EmojiCategory(id: "test", emojis: [item])
        emojiLoaderMock.categories = [category]
        let categories = await sut.getCategories()
        XCTAssertEqual(emojiLoaderMock.categories, categories)
    }
    
    func test_whenEmojisLoadedAndSearchStringEmpty_allCategoriesReturned() async throws {
        let item = EmojiItem(id: "test", name: "test", keywords: ["1", "2"], skins: ["🙂"])
        let category = EmojiCategory(id: "test", emojis: [item])
        emojiLoaderMock.categories = [category]
        let categories = await sut.getCategories(searchString: "")
        XCTAssertEqual(emojiLoaderMock.categories, categories)
    }
    
    func test_whenEmojisLoadedSecondTime_cachedValuesAreUsed() async throws {
        let categoriesForFirstLoad = [EmojiCategory(id: "test",
                                                    emojis: [EmojiItem(id: "test", name: "test", keywords: ["1", "2"], skins: ["🙂"])])]
        let categoriesForSecondLoad = [EmojiCategory(id: "test2",
                                                     emojis: [EmojiItem(id: "test2", name: "test2", keywords: ["3", "4"], skins: ["🫠"])])]
        emojiLoaderMock.categories = categoriesForFirstLoad
        _ = await sut.getCategories()
        emojiLoaderMock.categories = categoriesForSecondLoad
        let categories = await sut.getCategories()
        XCTAssertEqual(categories, categoriesForFirstLoad)
    }
    
    func test_whenEmojisSearched_correctNumberOfCategoriesReturned() async throws {
        let searchString = "smile"
        var categories = [EmojiCategory]()
        categories.append(EmojiCategory(id: "test",
                                        emojis: [EmojiItem(id: "\(searchString)_123",
                                                           name: "emoji0",
                                                           keywords: ["key1", "key1"],
                                                           skins: ["🙂"]),
                                                 EmojiItem(id: "emoji_1",
                                                           name: searchString,
                                                           keywords: ["key1", "key1"],
                                                           skins: ["🙂"]),
                                                 EmojiItem(id: "emoji_2",
                                                           name: "emoji2",
                                                           keywords: ["key1", "\(searchString)_123"],
                                                           skins: ["🙂"]),
                                                 EmojiItem(id: "emoji_3",
                                                           name: "emoji_3",
                                                           keywords: ["key1", "key1"],
                                                           skins: ["🙂"])]))
        categories.append(EmojiCategory(id: "test",
                                        emojis: [EmojiItem(id: "\(searchString)_123",
                                                           name: "emoji0",
                                                           keywords: ["key1", "key1"],
                                                           skins: ["🙂"])]))
        emojiLoaderMock.categories = categories
        _ = await sut.getCategories()
        let result = await sut.getCategories(searchString: searchString)
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result.first?.emojis.count, 3)
    }
}

private class EmojiLoaderMock: EmojiLoaderProtocol {
    var categories = [ElementX.EmojiCategory]()
    func load() async -> [ElementX.EmojiCategory] {
        categories
    }
}

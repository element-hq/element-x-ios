//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import XCTest

@testable import ElementX

@MainActor
final class EmojiProviderTests: XCTestCase {
    func testWhenEmojisLoadedCategoriesAreLoadedFromLoader() async throws {
        let item = EmojiItem(label: "test", unicode: "test", keywords: ["1", "2"], shortcodes: ["1", "2"])
        let category = EmojiCategory(id: "test", emojis: [item])
        
        let emojiLoaderMock = EmojiLoaderMock()
        emojiLoaderMock.categories = [category]
        
        let emojiProvider = EmojiProvider(loader: emojiLoaderMock)
        
        let categories = await emojiProvider.categories()
        XCTAssertEqual(emojiLoaderMock.categories, categories)
    }

    func testWhenEmojisLoadedAndSearchStringEmptyAllCategoriesReturned() async throws {
        let item = EmojiItem(label: "test", unicode: "test", keywords: ["1", "2"], shortcodes: ["1", "2"])
        let category = EmojiCategory(id: "test", emojis: [item])
        
        let emojiLoaderMock = EmojiLoaderMock()
        emojiLoaderMock.categories = [category]
        
        let emojiProvider = EmojiProvider(loader: emojiLoaderMock)
        
        let categories = await emojiProvider.categories(searchString: "")
        XCTAssertEqual(emojiLoaderMock.categories, categories)
    }

    func testWhenEmojisLoadedSecondTimeCachedValuesAreUsed() async throws {
        let item = EmojiItem(label: "test", unicode: "test", keywords: ["1", "2"], shortcodes: ["1", "2"])
        let item2 = EmojiItem(label: "test2", unicode: "test2", keywords: ["3", "4"], shortcodes: ["3", "4"])
        let categoriesForFirstLoad = [EmojiCategory(id: "test",
                                                    emojis: [item])]
        let categoriesForSecondLoad = [EmojiCategory(id: "test2",
                                                     emojis: [item2])]
        
        let emojiLoaderMock = EmojiLoaderMock()
        emojiLoaderMock.categories = categoriesForFirstLoad
        
        let emojiProvider = EmojiProvider(loader: emojiLoaderMock)
        
        _ = await emojiProvider.categories()
        emojiLoaderMock.categories = categoriesForSecondLoad
        
        let categories = await emojiProvider.categories()
        XCTAssertEqual(categories, categoriesForFirstLoad)
    }
    
    func testWhenEmojisSearchedCorrectNumberOfCategoriesReturned() async throws {
        let searchString = "smile"
        var categories = [EmojiCategory]()
        let item0WithSearchString = EmojiItem(label: "emoji0", unicode: "\(searchString)_123", keywords: ["key1", "key1"], shortcodes: ["key1", "key1"])
        let item1WithSearchString = EmojiItem(label: searchString, unicode: "emoji1", keywords: ["key1", "key1"], shortcodes: ["key1", "key1"])
        let item2WithSearchString = EmojiItem(label: "emoji_2", unicode: "emoji_2", keywords: ["key1", "\(searchString)_123"], shortcodes: ["key1", "key2"])
        let item3WithSearchString = EmojiItem(label: "emoji_2", unicode: "emoji_2", keywords: ["key1", "key1"], shortcodes: ["key1", "\(searchString)_123"])
        let item4WithoutSearchString = EmojiItem(label: "emoji_3", unicode: "emoji_3", keywords: ["key1", "key1"], shortcodes: ["key1", "key1"])
        let item5WithSearchString = EmojiItem(label: "emoji0", unicode: "\(searchString)_123", keywords: ["key1", "key1"], shortcodes: ["key1", "key1"])
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
        
        let emojiProvider = EmojiProvider(loader: emojiLoaderMock)
        
        _ = await emojiProvider.categories()
        let result = await emojiProvider.categories(searchString: searchString)
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

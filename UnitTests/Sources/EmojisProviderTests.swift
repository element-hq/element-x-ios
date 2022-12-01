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

final class EmojisProviderTests: XCTestCase {
    var sut: EmojisProvider!
    private var emojisLoaderMock: EmojisLoaderMock!
    
    @MainActor override func setUp() {
        emojisLoaderMock = EmojisLoaderMock()
        sut = EmojisProvider(loader: emojisLoaderMock)
    }
    
    func test_whenEmojisLoaded_categoriesAreLoadedFromLoader() async throws {
        let item = EmojiItem(id: "test", name: "test", keywords: ["1", "2"], skins: [try slightlySmilingFaceEmoji()])
        let category = EmojiCategory(id: "test", emojis: [item])
        emojisLoaderMock.categories = [category]
        let categories = await sut.load()
        XCTAssertEqual(emojisLoaderMock.categories, categories)
    }
    
    func test_whenEmojisLoadedSecondTime_cachedValuesAreUsed() async throws {
        let categoriesForFirstLoad = [EmojiCategory(id: "test",
                                                    emojis: [EmojiItem(id: "test", name: "test", keywords: ["1", "2"], skins: [try slightlySmilingFaceEmoji()])])]
        let categoriesForSecondLoad = [EmojiCategory(id: "test2",
                                                     emojis: [EmojiItem(id: "test2", name: "test2", keywords: ["3", "4"], skins: [try meltingFaceEmoji()])])]
        emojisLoaderMock.categories = categoriesForFirstLoad
        _ = await sut.load()
        emojisLoaderMock.categories = categoriesForSecondLoad
        let categories = await sut.load()
        XCTAssertEqual(categories, categoriesForFirstLoad)
    }
    
    private func slightlySmilingFaceEmoji() throws -> EmojiItemSkin {
        try XCTUnwrap(EmojiItemSkin(from: EmojiMartEmojiSkin(unified: "1f642", native: "🙂")))
    }
    
    private func meltingFaceEmoji() throws -> EmojiItemSkin {
        try XCTUnwrap(EmojiItemSkin(from: EmojiMartEmojiSkin(unified: "1fae0", native: "🫠")))
    }
}

private class EmojisLoaderMock: EmojisLoaderProtocol {
    var categories = [ElementX.EmojiCategory]()
    func load() async -> [ElementX.EmojiCategory] {
        categories
    }
}

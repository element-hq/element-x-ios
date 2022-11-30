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
    
    func test_whenEmojisLoaded_categoriesAreLoadedFromLoader() async {
        emojisLoaderMock.categories = [EmojiCategory(identifier: "test", emojis: [EmojiItem(shortName: "test", value: "🙂", name: "test")])]
        let categories = await sut.load()
        XCTAssertEqual(emojisLoaderMock.categories, categories)
    }
    
    func test_whenEmojisLoadedSecondTime_cachedValuesAreUsed() async {
        let categoriesForFirstLoad = [EmojiCategory(identifier: "test", emojis: [EmojiItem(shortName: "test", value: "🙂", name: "test")])]
        let categoriesForSecondLoad = [EmojiCategory(identifier: "test2", emojis: [EmojiItem(shortName: "tes2", value: "🙃", name: "test2")])]
        emojisLoaderMock.categories = categoriesForFirstLoad
        _ = await sut.load()
        emojisLoaderMock.categories = categoriesForSecondLoad
        let categories = await sut.load()
        XCTAssertEqual(categories, categoriesForFirstLoad)
    }
}

private class EmojisLoaderMock: EmojisLoaderProtocol {
    var categories = [ElementX.EmojiCategory]()
    func load() async -> [ElementX.EmojiCategory] {
        categories
    }
}

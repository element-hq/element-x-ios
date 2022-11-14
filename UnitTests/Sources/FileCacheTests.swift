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
import XCTest

@testable import ElementX

class FileCacheTests: XCTestCase {
    private var cache: FileCache!

    override func setUp() {
        cache = .default
    }

    override func tearDown() async throws {
        try cache.removeAll()
    }

    func testExistence() throws {
        let data = Data(repeating: 1, count: 32)
        let key = "some_key"
        let fileExtension = "mp4"

        let url1 = try cache.store(data, with: fileExtension, forKey: key)
        let url2 = cache.file(forKey: key, fileExtension: fileExtension)

        XCTAssertEqual(url1, url2)
    }

    func testRemove() throws {
        let data = Data(repeating: 1, count: 32)
        let key = "some_key"
        let fileExtension = "mp4"

        _ = try cache.store(data, with: fileExtension, forKey: key)
        try cache.remove(forKey: key, fileExtension: fileExtension)
        let url = cache.file(forKey: key, fileExtension: fileExtension)

        XCTAssertNil(url)
    }

    func testRemoveAll() throws {
        let data1 = Data(repeating: 1, count: 32)
        let key1 = "some_key_1"
        let fileExtension1 = "mp4"

        let data2 = Data(repeating: 1, count: 64)
        let key2 = "some_key_2"
        let fileExtension2 = "mp4"

        _ = try cache.store(data1, with: fileExtension1, forKey: key1)
        _ = try cache.store(data2, with: fileExtension2, forKey: key2)
        try cache.removeAll()
        let url1 = cache.file(forKey: key1, fileExtension: fileExtension1)
        let url2 = cache.file(forKey: key2, fileExtension: fileExtension2)

        XCTAssertNil(url1)
        XCTAssertNil(url2)
    }

    func testRemoveAllWhenEmpty() throws {
        XCTAssertNoThrow(try cache.removeAll())
    }
}

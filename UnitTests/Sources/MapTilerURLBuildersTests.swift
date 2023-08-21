//
// Copyright 2023 New Vector Ltd
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

import CoreLocation
@testable import ElementX
import XCTest

final class MapTilerURLBuildersTests: XCTestCase {
    private static let baseURL: URL = "http://www.foo.com"
    private static let apiKey = "some_key"

    func testStaticMapBuilder() {
        let builder = MapTilerStaticMap(baseURL: Self.baseURL, key: Self.apiKey)
        
        let url = builder.staticMapURL(for: .light,
                                       coordinates: .init(latitude: 1, longitude: 2),
                                       zoomLevel: 5,
                                       size: .init(width: 300, height: 200),
                                       attribution: .hidden)

        let expectedURL: URL = "http://www.foo.com/9bc819c8-e627-474a-a348-ec144fe3d810/static/2.000000,1.000000,5.000000/300x200@2x.png?attribution=false&key=some_key"
        XCTAssertEqual(url, expectedURL)
    }

    func testStaticMapBuilderWithAttribution() {
        let builder = MapTilerStaticMap(baseURL: Self.baseURL, key: Self.apiKey)

        let url = builder.staticMapURL(for: .dark,
                                       coordinates: .init(latitude: 1, longitude: 2),
                                       zoomLevel: 5,
                                       size: .init(width: 300, height: 200),
                                       attribution: .topLeft)

        let expectedURL: URL = "http://www.foo.com/dea61faf-292b-4774-9660-58fcef89a7f3/static/2.000000,1.000000,5.000000/300x200@2x.png?attribution=topleft&key=some_key"
        XCTAssertEqual(url, expectedURL)
    }

    func testDynamicMapBuilder() {
        let builder = MapTilerStyleBuilder(baseURL: Self.baseURL, key: Self.apiKey)
        let url = builder.dynamicMapURL(for: .dark)
        let expectedURL: URL = "http://www.foo.com/dea61faf-292b-4774-9660-58fcef89a7f3/style.json?key=some_key"
        XCTAssertEqual(url, expectedURL)
    }
}

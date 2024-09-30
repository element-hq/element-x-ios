//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
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

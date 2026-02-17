//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import CoreLocation
@testable import ElementX
import Testing

@Suite
struct MapTilerURLBuilderTests {
    private static let baseURL: URL = "http://www.foo.com"
    private static let apiKey = "some_key"
    private static let lightStyleID = "9bc819c8-e627-474a-a348-ec144fe3d810"
    private static let darkStyleID = "dea61faf-292b-4774-9660-58fcef89a7f3"
    
    var builder: MapTilerURLBuilderProtocol
    
    init() {
        builder = MapTilerConfiguration(baseURL: Self.baseURL,
                                        apiKey: Self.apiKey,
                                        lightStyleID: Self.lightStyleID,
                                        darkStyleID: Self.darkStyleID)
    }

    @Test
    func staticMapBuilder() {
        let url = builder.staticMapTileImageURL(for: .light,
                                                coordinates: .init(latitude: 1, longitude: 2),
                                                zoomLevel: 5,
                                                size: .init(width: 300, height: 200),
                                                attribution: .hidden)

        let expectedURL: URL = "http://www.foo.com/9bc819c8-e627-474a-a348-ec144fe3d810/static/2.000000,1.000000,5.000000/300x200@2x.png?key=some_key&attribution=false"
        #expect(url == expectedURL)
    }

    @Test
    func staticMapBuilderWithAttribution() {
        let url = builder.staticMapTileImageURL(for: .dark,
                                                coordinates: .init(latitude: 1, longitude: 2),
                                                zoomLevel: 5,
                                                size: .init(width: 300, height: 200),
                                                attribution: .topLeft)

        let expectedURL: URL = "http://www.foo.com/dea61faf-292b-4774-9660-58fcef89a7f3/static/2.000000,1.000000,5.000000/300x200@2x.png?key=some_key&attribution=topleft"
        #expect(url == expectedURL)
    }

    @Test
    func dynamicMapBuilder() {
        let url = builder.interactiveMapURL(for: .dark)
        let expectedURL: URL = "http://www.foo.com/dea61faf-292b-4774-9660-58fcef89a7f3/style.json?key=some_key"
        #expect(url == expectedURL)
    }
    
    @Test
    mutating func nilAPIKey() {
        let configuration = MapTilerConfiguration(baseURL: Self.baseURL,
                                                  apiKey: nil,
                                                  lightStyleID: Self.lightStyleID,
                                                  darkStyleID: Self.darkStyleID)
        #expect(!configuration.isEnabled)
        
        builder = configuration
        
        let staticMapURL = builder.staticMapTileImageURL(for: .dark,
                                                         coordinates: .init(latitude: 1, longitude: 2),
                                                         zoomLevel: 5,
                                                         size: .init(width: 300, height: 200),
                                                         attribution: .topLeft)
        #expect(staticMapURL == nil)
        
        let dynamicMapURL = builder.interactiveMapURL(for: .light)
        #expect(dynamicMapURL == nil)
    }
}

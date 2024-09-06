//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import CoreLocation

struct MapTilerStaticMap: MapTilerStaticMapProtocol {
    private let baseURL: URL
    private let key: String

    init(baseURL: URL, key: String) {
        self.baseURL = baseURL
        self.key = key
    }
    
    func staticMapURL(for style: MapTilerStyle, coordinates: CLLocationCoordinate2D, zoomLevel: Double, size: CGSize, attribution: MapTilerAttributionPlacement) -> URL? {
        var url: URL = baseURL
        url.appendPathComponent(style.rawValue, conformingTo: .item)
        url.appendPathComponent(String(format: "static/%f,%f,%f/%dx%d@2x.png", coordinates.longitude, coordinates.latitude, zoomLevel, Int(size.width), Int(size.height)), conformingTo: .png)
        url.append(queryItems: [.init(name: "attribution", value: attribution.rawValue)])
        let authorization = MapTilerAuthorization(key: key)
        return authorization.authorizeURL(url)
    }
}

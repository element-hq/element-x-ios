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

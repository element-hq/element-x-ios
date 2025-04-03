//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import CoreLocation

/// All of the configuration necessary to use MapTiler maps.
///
/// The style IDs need to be generated with the account that the API key belongs to. For more information read
/// [FORKING.md](https://github.com/element-hq/element-x-ios/blob/develop/docs/FORKING.md#setup-the-location-sharing)
struct MapTilerConfiguration {
    let baseURL: URL
    /// The API key for fetching map tiles. When not set, location sharing will be disabled and
    /// any received locations will be shown in the timeline with a generic blurred map image.
    let apiKey: String?
    /// A MapLibre style ID for a light-mode map.
    let lightStyleID: String
    /// A MapLibre style ID for a dark-mode map.
    let darkStyleID: String
    
    var isEnabled: Bool { apiKey != nil }
}

extension MapTilerConfiguration: MapTilerURLBuilderProtocol {
    func dynamicMapURL(for style: MapTilerStyle) -> URL? {
        var url = makeNewURL(for: style)
        url?.appendPathComponent("style.json", conformingTo: .json)
        return url
    }
    
    func staticMapURL(for style: MapTilerStyle,
                      coordinates: CLLocationCoordinate2D,
                      zoomLevel: Double,
                      size: CGSize,
                      attribution: MapTilerAttributionPlacement) -> URL? {
        var url = makeNewURL(for: style)
        url?.appendPathComponent(String(format: "static/%f,%f,%f/%dx%d@2x.png",
                                        coordinates.longitude,
                                        coordinates.latitude,
                                        zoomLevel,
                                        Int(size.width),
                                        Int(size.height)),
                                 conformingTo: .png)
        url?.append(queryItems: [.init(name: "attribution", value: attribution.rawValue)])
        return url
    }
    
    // MARK: Private
    
    private func makeNewURL(for style: MapTilerStyle) -> URL? {
        guard let apiKey else { return nil }
        
        var url: URL = baseURL
        url.appendPathComponent(styleID(for: style), conformingTo: .item)
        url.append(queryItems: [URLQueryItem(name: "key", value: apiKey)])
        return url
    }
    
    private func styleID(for style: MapTilerStyle) -> String {
        switch style {
        case .light: lightStyleID
        case .dark: darkStyleID
        }
    }
}

//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import CoreLocation

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

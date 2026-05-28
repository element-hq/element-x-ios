//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import CoreLocation

extension MapTilerSettings: MapTilerURLBuilderProtocol {
    /// For interactive MGLMap components
    func interactiveMapURL(for style: MapTilerStyle) -> URL? {
        switch self {
        case .configuration(let configuration):
            var url = configuration.styleURL(for: style)
            url?.appendPathComponent("style.json", conformingTo: .json)
            return url
        case .url(let url):
            return url
        }
    }

    /// Used in the timeline where a full MGLMapView loading is unwanted
    func staticMapTileImageURL(for style: MapTilerStyle,
                               coordinates: CLLocationCoordinate2D,
                               zoomLevel: Double,
                               size: CGSize,
                               attribution: MapTilerAttributionPlacement) -> URL? {
        let staticComponent = String(format: "static/%f,%f,%f/%dx%d@2x.png",
                                     coordinates.longitude,
                                     coordinates.latitude,
                                     zoomLevel,
                                     Int(size.width),
                                     Int(size.height))
        switch self {
        case .configuration(let configuration):
            var url = configuration.styleURL(for: style)
            url?.appendPathComponent(staticComponent, conformingTo: .png)
            url?.append(queryItems: [.init(name: "attribution", value: attribution.rawValue)])
            return url
        case .url(let url):
            // The override is a full URL to a `style.json` (with any necessary query items,
            // such as an embedded API key). Derive the static URL by replacing the trailing
            // `style.json` component while preserving existing query items.
            guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return nil }
            var pathComponents = components.path.split(separator: "/", omittingEmptySubsequences: false).map(String.init)
            guard pathComponents.last == "style.json" else { return nil }
            pathComponents.removeLast()
            pathComponents.append(staticComponent)
            components.path = pathComponents.joined(separator: "/")

            var queryItems = components.queryItems ?? []
            queryItems.append(.init(name: "attribution", value: attribution.rawValue))
            components.queryItems = queryItems

            return components.url
        }
    }
}

// MARK: - Private

private extension MapTilerSettings.Configuration {
    func styleURL(for style: MapTilerStyle) -> URL? {
        guard let apiKey else { return nil }

        var url: URL = baseURL
        url.appendPathComponent(styleID(for: style), conformingTo: .item)
        url.append(queryItems: [URLQueryItem(name: "key", value: apiKey)])
        return url
    }

    func styleID(for style: MapTilerStyle) -> String {
        switch style {
        case .light: lightStyleID
        case .dark: darkStyleID
        }
    }
}

//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import CoreLocation

protocol MapTilerURLBuilderProtocol {
    func interactiveMapURL(for style: MapTilerStyle) -> URL?
    
    func staticMapTileImageURL(for style: MapTilerStyle,
                               coordinates: CLLocationCoordinate2D,
                               zoomLevel: Double,
                               size: CGSize,
                               attribution: MapTilerAttributionPlacement) -> URL?
}

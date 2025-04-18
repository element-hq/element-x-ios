//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import CoreLocation

protocol MapTilerURLBuilderProtocol {
    func dynamicMapURL(for style: MapTilerStyle) -> URL?
    
    func staticMapURL(for style: MapTilerStyle,
                      coordinates: CLLocationCoordinate2D,
                      zoomLevel: Double,
                      size: CGSize,
                      attribution: MapTilerAttributionPlacement) -> URL?
}

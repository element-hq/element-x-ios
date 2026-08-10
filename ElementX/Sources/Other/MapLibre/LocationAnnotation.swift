//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import CoreLocation
import Foundation
import MapInterface

final class LocationAnnotation: MapAnnotation {
    let kind: LocationMarkerKind

    // MARK: - Setup

    init(id: String, coordinate: CLLocationCoordinate2D, kind: LocationMarkerKind) {
        self.kind = kind
        super.init(id: id, coordinate: coordinate)
    }
}

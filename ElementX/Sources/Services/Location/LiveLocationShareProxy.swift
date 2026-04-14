//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRustSDK

struct LiveLocationShareProxy: Hashable {
    let userID: String
    let geoURI: GeoURI?
    let timestamp: Date
    let timeoutDate: Date
}

extension LiveLocationShareProxy {
    init(liveLocationShare: LiveLocationShare) {
        userID = liveLocationShare.userId
        if let geoURI = liveLocationShare.lastLocation?.location.geoUri {
            self.geoURI = GeoURI(string: geoURI)
        } else {
            geoURI = nil
        }
        timestamp = Date(timeIntervalSince1970: Double(liveLocationShare.startTs))
        timeoutDate = timestamp.addingTimeInterval(Double(liveLocationShare.timeout) / 1000)
    }
}

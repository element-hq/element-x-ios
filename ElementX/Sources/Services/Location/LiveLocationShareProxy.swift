//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRustSDK

struct LiveLocationShare: Hashable {
    let userID: String
    let geoURI: GeoURI?
    let timestamp: Date
    let timeoutDate: Date
    
    init(userID: String, geoURI: GeoURI?, timestamp: Date, timeoutDate: Date) {
        self.userID = userID
        self.geoURI = geoURI
        self.timestamp = timestamp
        self.timeoutDate = timeoutDate
    }
    
    init(liveLocationShare: MatrixRustSDK.LiveLocationShare) {
        userID = liveLocationShare.userId
        geoURI = (liveLocationShare.lastLocation?.location.geoUri).flatMap(GeoURI.init(string:))
        timestamp = Date(timeIntervalSince1970: Double(liveLocationShare.startTs))
        timeoutDate = timestamp.addingTimeInterval(Double(liveLocationShare.timeout) / 1000)
    }
}

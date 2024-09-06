//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

struct LocationRoomTimelineItemContent: Hashable {
    let body: String
    let geoURI: GeoURI?
    let description: String?

    init(body: String,
         geoURI: GeoURI? = nil,
         description: String? = nil) {
        self.body = body
        self.geoURI = geoURI
        self.description = description
    }
}

//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import MatrixRustSDK

struct LocationRoomTimelineItemContent: Hashable {
    let body: String
    let geoURI: GeoURI?
    let kind: StaticLocationKind

    init(body: String,
         geoURI: GeoURI? = nil,
         kind: StaticLocationKind = .sender) {
        self.body = body
        self.geoURI = geoURI
        self.kind = kind
    }
}

enum StaticLocationKind {
    case sender
    case pin
    
    init(from asset: AssetType?) {
        switch asset {
        case .pin:
            self = .pin
        default:
            self = .sender
        }
    }
}

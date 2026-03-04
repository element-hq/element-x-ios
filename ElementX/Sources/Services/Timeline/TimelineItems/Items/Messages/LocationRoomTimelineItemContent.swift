//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import MatrixRustSDK

struct LocationRoomTimelineItemContent: Hashable {
    enum Kind {
        case sender
        case pin
        
        init(from asset: AssetType?) {
            self = switch asset {
            case .pin:
                .pin
            case .sender, .none:
                .sender
            }
        }
    }
    
    let body: String
    let geoURI: GeoURI?
    let kind: Kind

    init(body: String,
         geoURI: GeoURI? = nil,
         kind: Kind = .sender) {
        self.body = body
        self.geoURI = geoURI
        self.kind = kind
    }
}

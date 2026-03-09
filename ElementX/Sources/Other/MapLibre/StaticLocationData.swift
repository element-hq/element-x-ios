//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

struct StaticLocationData: Hashable {
    let sender: TimelineItemSender
    let geoURI: GeoURI
    let kind: StaticLocationKind
    let timestamp: Date
}

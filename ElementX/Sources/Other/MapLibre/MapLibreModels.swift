//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// The style to show a map in.
///
/// There can be any number of styles, we have defined one for light and another for dark.
enum MapTilerStyle {
    case light
    case dark
}

enum MapTilerAttributionPlacement: String {
    case bottomRight = "bottomright"
    case bottomLeft = "bottomleft"
    case topLeft = "topleft"
    case topRight = "topright"
    case hidden = "false"
}

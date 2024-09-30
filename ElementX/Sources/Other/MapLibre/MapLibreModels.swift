//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

/*
 Behavior mode of the current user's location, can be hidden, only shown and shown following the user
 */
enum ShowUserLocationMode {
    /// this mode will show the user pin in map
    case show
    /// this mode will show the user pin in map and track him, panning the map automatically
    case showAndFollow
    /// this mode will not show the user pin in map
    case hide
}

enum MapLibreError: Error {
    case failedLoadingMap
    case failedLocatingUser
}

enum MapTilerAttributionPlacement: String {
    case bottomRight = "bottomright"
    case bottomLeft = "bottomleft"
    case topLeft = "topleft"
    case topRight = "topright"
    case hidden = "false"
}

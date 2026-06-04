//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/**
 Behavior mode of the current user's location, can be hidden, only shown and shown following the user
 */
enum ShowUserLocationMode: Equatable {
    /// this mode will show the user pin in map
    case show
    /// this mode will show the user pin in map and track him, panning the map automatically
    case showAndFollow
    /// this mode will not show the user pin in map
    case hide
    /// this mode will not show the user pin in map and will follow the marker with the given id,
    /// panning the map automatically.
    case hideAndFollowMarker(id: String)
    
    /// The id of the marker the map should follow when in the `hideAndFollowMarker` mode, nil otherwise.
    var followedMarkerID: String? {
        guard case .hideAndFollowMarker(let id) = self else { return nil }
        return id
    }
}

enum MapLibreError: Error {
    case failedLoadingMap
    case failedLocatingUser
}

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

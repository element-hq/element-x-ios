//
// Copyright 2026 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import CoreLocation
import Foundation

/**
 Behavior mode of the current user's location, can be hidden, only shown and shown following the user
 */
public enum ShowUserLocationMode: Equatable {
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
    public var followedMarkerID: String? {
        guard case .hideAndFollowMarker(let id) = self else { return nil }
        return id
    }
}

public enum MapLibreError: Error, Hashable {
    case failedLoadingMap
    case failedLocatingUser
}

/// The severity of a map log message forwarded to the app.
public enum MapLogSeverity {
    case error
    case warning
    case info
    case debug
    case verbose
}

/// A marker shown on the map, identified so that it can be moved in place when its coordinate changes.
public struct MapAnnotation {
    public let id: String
    public let coordinate: CLLocationCoordinate2D
    
    public init(id: String, coordinate: CLLocationCoordinate2D) {
        self.id = id
        self.coordinate = coordinate
    }
}

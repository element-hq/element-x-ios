//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import CoreLocation
import SwiftUI

// The types shared between the app and the MapLibreShim framework.
//
// The app deliberately doesn't link MapLibre: its static initialisers cost tens of
// milliseconds on every cold launch, for a map that only appears once a location
// screen is opened. Instead the app links this (tiny) framework, MapLibreShim links
// MapLibre, and the app dlopens the shim the first time a map is actually shown.

/// Behavior mode of the current user's location, can be hidden, only shown and shown following the user
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

/// An annotation rendered on the interactive map.
///
/// A class (rather than a struct) because MapLibre tracks annotations by identity
/// and repositions their views through KVO on `coordinate`.
open class MapAnnotation: NSObject, Identifiable {
    public let id: String
    // @objc dynamic is required to make animations work
    @objc public dynamic var coordinate: CLLocationCoordinate2D
    /// Builds the SwiftUI view shown at the annotation's position.
    public var makeContent: () -> AnyView = { AnyView(EmptyView()) }

    public init(id: String, coordinate: CLLocationCoordinate2D) {
        self.id = id
        self.coordinate = coordinate
        super.init()
    }
}

public struct InteractiveMapOptions {
    /// the final zoom level used when the first user location emit
    public let zoomLevel: Double
    /// The initial zoom level used when the map it firstly loaded and the user location is not yet available, in case of annotations this property is not being used
    public let initialZoomLevel: Double

    /// The initial map center
    public let mapCenter: CLLocationCoordinate2D

    /// Map annotations
    public let annotations: [MapAnnotation]

    /// The tint used for e.g. the user location pin.
    public var tintColor: UIColor = .systemBlue

    public init(zoomLevel: Double, initialZoomLevel: Double, mapCenter: CLLocationCoordinate2D, annotations: [MapAnnotation] = []) {
        self.zoomLevel = zoomLevel
        self.initialZoomLevel = initialZoomLevel
        self.mapCenter = mapCenter
        self.annotations = annotations
    }
}

/// Implemented by MapLibreShim's entry point, which the app instantiates after
/// dlopen-ing the framework.
public protocol InteractiveMapViewBuilding {
    /// Routes MapLibre's logs into the app's logger. Call once after loading the shim.
    func configureLogging(_ handler: @escaping @Sendable (MapLogSeverity, String) -> Void)

    /// Builds the interactive map view. The app-side `MapLibreMapView` forwards every
    /// body evaluation here so SwiftUI updates flow through to the underlying map.
    func makeMapView(styleURL: @escaping (_ isDarkMode: Bool) -> URL?,
                     options: InteractiveMapOptions,
                     showsUserLocationMode: Binding<ShowUserLocationMode>,
                     error: Binding<MapLibreError?>,
                     mapCenterCoordinate: Binding<CLLocationCoordinate2D?>,
                     hasLoadedUserLocation: Binding<Bool>,
                     isLocationAuthorized: Binding<Bool?>,
                     geolocationUncertainty: Binding<CLLocationAccuracy?>,
                     userDidPan: (() -> Void)?) -> AnyView
}

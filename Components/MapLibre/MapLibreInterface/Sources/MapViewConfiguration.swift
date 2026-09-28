//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import CoreLocation
import SwiftUI

/// Everything the map implementation needs in order to render, expressed without app
/// types so that the implementation framework can be loaded on demand.
public struct MapViewConfiguration {
    /// the final zoom level used when the first user location emit
    public let zoomLevel: Double
    /// The initial zoom level used when the map it firstly loaded and the user location is not yet available, in case of annotations this property is not being used
    public let initialZoomLevel: Double
    
    /// The initial map center
    public let mapCenter: CLLocationCoordinate2D
    
    /// Map annotations
    public let annotations: [MapAnnotation]
    
    /// The style to load the map with, for either the dark or the light appearance.
    public let styleURL: (_ isDark: Bool) -> URL?
    
    public let tintColor: UIColor
    
    /// The content of the marker representing the annotation with the given id.
    public let markerView: (_ annotationID: String) -> AnyView?
    
    /// Behavior mode of the current user's location, can be hidden, only shown and shown following the user
    public let showsUserLocationMode: Binding<ShowUserLocationMode>
    /// Bind view errors if any
    public let error: Binding<MapLibreError?>
    /// Coordinate of the center of the map
    public let mapCenterCoordinate: Binding<CLLocationCoordinate2D?>
    public let hasLoadedUserLocation: Binding<Bool>
    public let isLocationAuthorized: Binding<Bool?>
    /// The radius of uncertainty for the location, measured in meters.
    public let geolocationUncertainty: Binding<CLLocationAccuracy?>
    
    /// Called when the user pan on the map
    public let userDidPan: (() -> Void)?
    
    public init(zoomLevel: Double,
                initialZoomLevel: Double,
                mapCenter: CLLocationCoordinate2D,
                annotations: [MapAnnotation] = [],
                styleURL: @escaping (_ isDark: Bool) -> URL?,
                tintColor: UIColor,
                markerView: @escaping (_ annotationID: String) -> AnyView?,
                showsUserLocationMode: Binding<ShowUserLocationMode>,
                error: Binding<MapLibreError?>,
                mapCenterCoordinate: Binding<CLLocationCoordinate2D?>,
                hasLoadedUserLocation: Binding<Bool>,
                isLocationAuthorized: Binding<Bool?>,
                geolocationUncertainty: Binding<CLLocationAccuracy?>,
                userDidPan: (() -> Void)? = nil) {
        self.zoomLevel = zoomLevel
        self.initialZoomLevel = initialZoomLevel
        self.mapCenter = mapCenter
        self.annotations = annotations
        self.styleURL = styleURL
        self.tintColor = tintColor
        self.markerView = markerView
        self.showsUserLocationMode = showsUserLocationMode
        self.error = error
        self.mapCenterCoordinate = mapCenterCoordinate
        self.hasLoadedUserLocation = hasLoadedUserLocation
        self.isLocationAuthorized = isLocationAuthorized
        self.geolocationUncertainty = geolocationUncertainty
        self.userDidPan = userDidPan
    }
}

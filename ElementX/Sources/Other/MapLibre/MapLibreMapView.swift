//
// Copyright 2026 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import CoreLocation
import MapLibreInterface
import SwiftUI

/// The interactive map, rendered by the `MapLibreShim` framework which is loaded on first use.
///
/// The app deliberately doesn't link MapLibre: dyld would otherwise load it, run its static
/// initialisers and register its classes on every single launch, for a map that is only shown
/// on the location screens.
struct MapLibreMapView: View {
    struct Options {
        /// the final zoom level used when the first user location emit
        let zoomLevel: Double
        /// The initial zoom level used when the map it firstly loaded and the user location is not yet available, in case of annotations this property is not being used
        let initialZoomLevel: Double
        
        /// The initial map center
        let mapCenter: CLLocationCoordinate2D
        
        /// Map annotations
        let annotations: [LocationAnnotation]
        
        init(zoomLevel: Double, initialZoomLevel: Double, mapCenter: CLLocationCoordinate2D, annotations: [LocationAnnotation] = []) {
            self.zoomLevel = zoomLevel
            self.initialZoomLevel = initialZoomLevel
            self.mapCenter = mapCenter
            self.annotations = annotations
        }
    }
    
    let mapURLBuilder: MapTilerURLBuilderProtocol
    
    let options: Options
    
    let mediaProvider: MediaProviderProtocol?
    
    /// Behavior mode of the current user's location, can be hidden, only shown and shown following the user
    @Binding var showsUserLocationMode: ShowUserLocationMode
    /// Bind view errors if any
    @Binding var error: MapLibreError?
    /// Coordinate of the center of the map
    @Binding var mapCenterCoordinate: CLLocationCoordinate2D?
    @Binding var hasLoadedUserLocation: Bool
    @Binding var isLocationAuthorized: Bool?
    /// The radius of uncertainty for the location, measured in meters.
    @Binding var geolocationUncertainty: CLLocationAccuracy?
    
    /// Called when the user pan on the map
    var userDidPan: (() -> Void)?
    
    var body: some View {
        if let shim = MapLibreLoader.shim {
            shim.makeMapView(configuration: configuration)
        } else {
            // The shim failed to load, surface it the same way as a map loading failure.
            Color.clear
                .onAppear { error = .failedLoadingMap }
        }
    }
    
    /// The configuration for the shim, with the app-only pieces (marker views, tint, styles)
    /// resolved into the shared types it understands.
    private var configuration: MapViewConfiguration {
        let annotations = options.annotations
        let mapURLBuilder = mapURLBuilder
        let mediaProvider = mediaProvider
        
        return .init(zoomLevel: options.zoomLevel,
                     initialZoomLevel: options.initialZoomLevel,
                     mapCenter: options.mapCenter,
                     annotations: annotations.map { .init(id: $0.id, coordinate: $0.coordinate) },
                     styleURL: { mapURLBuilder.interactiveMapURL(for: $0 ? .dark : .light) },
                     tintColor: .compound.iconAccentPrimary,
                     markerView: { annotationID in
                         guard let kind = annotations.first(where: { $0.id == annotationID })?.kind else { return nil }
                         return AnyView(LocationMarkerView(kind: kind, mediaProvider: mediaProvider))
                     },
                     showsUserLocationMode: $showsUserLocationMode,
                     error: $error,
                     mapCenterCoordinate: $mapCenterCoordinate,
                     hasLoadedUserLocation: $hasLoadedUserLocation,
                     isLocationAuthorized: $isLocationAuthorized,
                     geolocationUncertainty: $geolocationUncertainty,
                     userDidPan: userDidPan)
    }
}

/// Loads the `MapLibreShim` framework on first use.
enum MapLibreLoader {
    static let shim: MapLibreShimProtocol? = {
        guard let frameworksPath = Bundle.main.privateFrameworksPath else {
            MXLog.error("Missing frameworks path.")
            return nil
        }
        
        guard dlopen("\(frameworksPath)/MapLibreShim.framework/MapLibreShim", RTLD_NOW) != nil else {
            MXLog.error("Failed loading MapLibreShim: \(dlerror().map { String(cString: $0) } ?? "unknown error")")
            return nil
        }
        
        guard let shimClass = NSClassFromString("MapLibreShim") as? NSObject.Type,
              let shim = shimClass.init() as? MapLibreShimProtocol else {
            MXLog.error("Failed resolving MapLibreShim.")
            return nil
        }
        
        shim.configureLogging { severity, message in
            switch severity {
            case .error:
                MXLog.error(message)
            case .warning:
                MXLog.warning(message)
            case .info:
                MXLog.info(message)
            case .debug:
                MXLog.debug(message)
            case .verbose:
                MXLog.verbose(message)
            }
        }
        
        return shim
    }()
}

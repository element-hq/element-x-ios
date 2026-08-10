//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import CoreLocation
import MapInterface
import SwiftUI

/// The interactive map, rendered by the dlopen'd MapLibreShim framework.
///
/// The app deliberately doesn't link MapLibre: its static initialisers cost tens of
/// milliseconds on every cold launch, for a map that only appears once a location
/// screen is opened. This wrapper keeps the old `MapLibreMapView` call-site surface
/// and loads the shim (and with it MapLibre) the first time a map is actually shown.
struct MapLibreMapView: View {
    typealias Options = InteractiveMapOptions

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
        if let builder = MapLibreShimLoader.builder {
            builder.makeMapView(styleURL: { [mapURLBuilder] isDarkMode in
                                    mapURLBuilder.interactiveMapURL(for: isDarkMode ? .dark : .light)
                                },
                                options: resolvedOptions,
                                showsUserLocationMode: $showsUserLocationMode,
                                error: $error,
                                mapCenterCoordinate: $mapCenterCoordinate,
                                hasLoadedUserLocation: $hasLoadedUserLocation,
                                isLocationAuthorized: $isLocationAuthorized,
                                geolocationUncertainty: $geolocationUncertainty,
                                userDidPan: userDidPan)
        } else {
            // The shim failed to load, surface it the same way as a map loading failure.
            Color.clear
                .onAppear { error = .failedLoadingMap }
        }
    }

    /// The options with the app-only pieces (marker views, tint) resolved into
    /// the shared types the shim understands.
    private var resolvedOptions: Options {
        for case let annotation as LocationAnnotation in options.annotations {
            annotation.makeContent = { [kind = annotation.kind, mediaProvider] in
                AnyView(LocationMarkerView(kind: kind, mediaProvider: mediaProvider))
            }
        }

        var options = options
        options.tintColor = .compound.iconAccentPrimary
        return options
    }
}

/// Loads the MapLibreShim framework on first use and vends its map view builder.
enum MapLibreShimLoader {
    static let builder: InteractiveMapViewBuilding? = {
        guard let frameworksPath = Bundle.main.privateFrameworksPath else {
            return nil
        }

        guard dlopen(frameworksPath + "/MapLibreShim.framework/MapLibreShim", RTLD_NOW) != nil else {
            MXLog.error("Failed loading MapLibreShim: \(dlerror().map { String(cString: $0) } ?? "unknown error")")
            return nil
        }

        guard let builderClass = NSClassFromString("MapLibreShimBuilder") as? NSObject.Type,
              let builder = builderClass.init() as? InteractiveMapViewBuilding else {
            MXLog.error("MapLibreShimBuilder missing from MapLibreShim")
            return nil
        }

        builder.configureLogging { severity, message in
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

        return builder
    }()
}

//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import CoreLocation
import MapInterface
import MapLibre
import SwiftUI

/// Conforms the shared annotation class to MapLibre's annotation protocol, so annotations
/// built by the app can be added to the map directly (keeping identity and KVO intact).
extension MapAnnotation: @retroactive MLNAnnotation {}

/// The shim's entry point: the app looks this class up by name through the ObjC runtime
/// after dlopen-ing the framework, keeping MapLibre off its own launch path.
@objc(MapLibreShimBuilder)
public final class MapLibreShimBuilder: NSObject, InteractiveMapViewBuilding {
    public func configureLogging(_ handler: @escaping @Sendable (MapLogSeverity, String) -> Void) {
        MLNLoggingConfiguration.shared.loggingLevel = .debug
        MLNLoggingConfiguration.shared.handler = { loggingLevel, _, _, message in
            switch loggingLevel {
            case .error:
                handler(.error, message)
            case .warning:
                handler(.warning, message)
            case .info:
                handler(.info, message)
            case .debug:
                handler(.debug, message)
            case .verbose:
                handler(.verbose, message)
            default:
                break
            }
        }
    }

    public func makeMapView(styleURL: @escaping (_ isDarkMode: Bool) -> URL?,
                            options: InteractiveMapOptions,
                            showsUserLocationMode: Binding<ShowUserLocationMode>,
                            error: Binding<MapLibreError?>,
                            mapCenterCoordinate: Binding<CLLocationCoordinate2D?>,
                            hasLoadedUserLocation: Binding<Bool>,
                            isLocationAuthorized: Binding<Bool?>,
                            geolocationUncertainty: Binding<CLLocationAccuracy?>,
                            userDidPan: (() -> Void)?) -> AnyView {
        AnyView(MapLibreMapView(styleURL: styleURL,
                                options: options,
                                showsUserLocationMode: showsUserLocationMode,
                                error: error,
                                mapCenterCoordinate: mapCenterCoordinate,
                                hasLoadedUserLocation: hasLoadedUserLocation,
                                isLocationAuthorized: isLocationAuthorized,
                                geolocationUncertainty: geolocationUncertainty,
                                userDidPan: userDidPan))
    }
}

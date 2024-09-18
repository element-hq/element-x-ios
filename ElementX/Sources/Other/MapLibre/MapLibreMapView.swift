//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import Mapbox
import SwiftUI

struct MapLibreMapView: UIViewRepresentable {
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
    
    // MARK: - Properties
    
    @Environment(\.colorScheme) private var colorScheme
    
    let builder: MapTilerStyleBuilderProtocol

    let options: Options
    
    /// Behavior mode of the current user's location, can be hidden, only shown and shown following the user
    @Binding var showsUserLocationMode: ShowUserLocationMode
    /// Bind view errors if any
    @Binding var error: MapLibreError?
    /// Coordinate of the center of the map
    @Binding var mapCenterCoordinate: CLLocationCoordinate2D?
    @Binding var isLocationAuthorized: Bool?
    /// The radius of uncertainty for the location, measured in meters.
    @Binding var geolocationUncertainty: CLLocationAccuracy?
    
    /// Called when the user pan on the map
    var userDidPan: (() -> Void)?
    
    // MARK: - UIViewRepresentable
    
    func makeUIView(context: Context) -> MGLMapView {
        let mapView = makeMapView()
        mapView.delegate = context.coordinator
        setupMap(mapView: mapView, with: options)
        return mapView
    }
    
    func updateUIView(_ mapView: MGLMapView, context: Context) {
        // Don't set the same value twice. Otherwise, if there is an error loading the map, a loop
        // is caused as the `error` binding being set, which triggers this update, which sets a
        // new URL, which causes another error, and so it goes on round and round in a circle.
        let dynamicMapURL = builder.dynamicMapURL(for: .init(colorScheme))
        if mapView.styleURL != dynamicMapURL {
            mapView.styleURL = dynamicMapURL
        }
        
        showUserLocation(in: mapView)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // MARK: - Private

    private func setupMap(mapView: MGLMapView, with options: Options) {
        mapView.addAnnotations(options.annotations)
        mapView.zoomLevel = options.annotations.isEmpty ? options.initialZoomLevel : options.zoomLevel
        mapView.centerCoordinate = options.mapCenter
    }
    
    private func makeMapView() -> MGLMapView {
        let mapView = MGLMapView(frame: .zero, styleURL: colorScheme == .dark ? builder.dynamicMapURL(for: .dark) : builder.dynamicMapURL(for: .light))
        mapView.logoViewPosition = .topLeft
        mapView.attributionButtonPosition = .topLeft
        mapView.attributionButtonMargins = .init(x: mapView.logoView.frame.maxX + 8, y: mapView.logoView.center.y / 2)
        mapView.tintColor = .black
        mapView.allowsRotating = false
        mapView.allowsTilting = false
        return mapView
    }
    
    private func showUserLocation(in mapView: MGLMapView) {
        switch (showsUserLocationMode, options.annotations) {
        case (.showAndFollow, _):
            mapView.userTrackingMode = .follow
        case (.show, let annotations) where !annotations.isEmpty:
            // In the show mode, if there are annotations, we check the authorizationStatus,
            // if it's not determined, we wont prompt the user with a request for permissions,
            // because they should be able to see the annotations without sharing their location information.
            guard mapView.locationManager.authorizationStatus != .notDetermined else { return }
            fallthrough
        case (.show, _):
            mapView.showsUserLocation = true
            mapView.setUserTrackingMode(.none, animated: false, completionHandler: nil)
        case (.hide, _):
            mapView.showsUserLocation = false
            mapView.setUserTrackingMode(.none, animated: false, completionHandler: nil)
        }
    }
}

// MARK: - Coordinator

extension MapLibreMapView {
    class Coordinator: NSObject, MGLMapViewDelegate {
        // MARK: - Properties

        var mapLibreView: MapLibreMapView
        
        private var previousUserLocation: MGLUserLocation?

        // MARK: - Setup

        init(_ mapLibreView: MapLibreMapView) {
            self.mapLibreView = mapLibreView
        }
        
        // MARK: - MGLMapViewDelegate
        
        func mapView(_ mapView: MGLMapView, viewFor annotation: MGLAnnotation) -> MGLAnnotationView? {
            guard let annotation = annotation as? LocationAnnotation else {
                return nil
            }
            return LocationAnnotationView(annotation: annotation)
        }
        
        func mapViewDidFailLoadingMap(_ mapView: MGLMapView, withError error: Error) {
            if mapLibreView.error != .failedLoadingMap {
                mapLibreView.error = .failedLoadingMap
            }
        }
        
        func mapView(_ mapView: MGLMapView, didUpdate userLocation: MGLUserLocation?) {
            guard let userLocation else { return }

            if previousUserLocation == nil, mapLibreView.options.annotations.isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    mapView.setCenter(userLocation.coordinate, zoomLevel: self.mapLibreView.options.zoomLevel, animated: true)
                }
            }

            previousUserLocation = userLocation
            updateGeolocationUncertainty(location: userLocation)
        }
        
        func mapView(_ mapView: MGLMapView, didChangeLocationManagerAuthorization manager: MGLLocationManager) {
            switch manager.authorizationStatus {
            case .denied, .restricted:
                mapLibreView.isLocationAuthorized = false
            case .authorizedAlways, .authorizedWhenInUse:
                mapLibreView.isLocationAuthorized = true
            case .notDetermined:
                mapLibreView.isLocationAuthorized = nil
            @unknown default:
                break
            }
        }
        
        func mapView(_ mapView: MGLMapView, regionDidChangeAnimated animated: Bool) {
            // Avoid `Publishing changes from within view update` warnings
            DispatchQueue.main.async { [mapLibreView] in
                mapLibreView.mapCenterCoordinate = mapView.centerCoordinate
            }
        }

        func mapView(_ mapView: MGLMapView, shouldChangeFrom oldCamera: MGLMapCamera, to newCamera: MGLMapCamera, reason: MGLCameraChangeReason) -> Bool {
            // we send the userDidPan event only for the reasons that actually will change the map center, and not zoom only / rotations only events.
            switch reason {
            case .gesturePan,
                 .gesturePinch,
                 .gestureRotate:
                mapLibreView.userDidPan?()
            case .gestureOneFingerZoom,
                 .gestureTilt,
                 .gestureZoomIn,
                 .gestureZoomOut,
                 .programmatic,
                 .resetNorth,
                 .transitionCancelled:
                break
            default:
                break
            }
            return true
        }

        // MARK: Callout

        func mapView(_ mapView: MGLMapView, annotationCanShowCallout annotation: MGLAnnotation) -> Bool {
            false
        }

        // MARK: Private

        private func updateGeolocationUncertainty(location: MGLUserLocation) {
            guard let clLocation = location.location, clLocation.horizontalAccuracy >= 0 else {
                mapLibreView.geolocationUncertainty = nil
                return
            }

            mapLibreView.geolocationUncertainty = clLocation.horizontalAccuracy
        }
    }
}

// MARK: - MGLMapView convenient methods

private extension MapTilerStyle {
    init(_ colorScheme: ColorScheme) {
        switch colorScheme {
        case .light:
            self = .dark
        case .dark:
            self = .dark
        @unknown default:
            fatalError()
        }
    }
}

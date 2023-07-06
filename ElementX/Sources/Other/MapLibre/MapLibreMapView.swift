//
// Copyright 2023 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Combine
import Mapbox
import SwiftUI

struct MapLibreMapView: UIViewRepresentable {
    struct Options {
        let zoomLevel: Double
        /// The initial zoom level
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
    let error: Binding<MapLibreError?>
    
    /// Coordinate of the center of the map
    @Binding var mapCenterCoordinate: CLLocationCoordinate2D?

    @Binding var isLocationAuthorized: Bool?
    
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
        mapView.styleURL = builder.dynamicMapURL(for: .init(colorScheme))
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
        return mapView
    }
    
    private func showUserLocation(in mapView: MGLMapView) {
        switch (showsUserLocationMode, options.annotations) {
        case (.showAndFollow, _):
            mapView.userTrackingMode = .follow
        case (.show, let annotations) where !annotations.isEmpty:
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
            mapLibreView.error.wrappedValue = .failedLoadingMap
        }
        
        func mapView(_ mapView: MGLMapView, didUpdate userLocation: MGLUserLocation?) {
            guard let userLocation else { return }

            if previousUserLocation == nil, mapLibreView.options.annotations.isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    mapView.setCenter(userLocation.coordinate, zoomLevel: self.mapLibreView.options.zoomLevel, animated: true)
                }
            }

            previousUserLocation = userLocation
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
            // Fixes: "Publishing changes from within view updates is not allowed, this will cause undefined behavior."
            DispatchQueue.main.async { [mapLibreView] in
                mapLibreView.mapCenterCoordinate = mapView.centerCoordinate
            }
        }
        
        // MARK: Callout
                
        func mapView(_ mapView: MGLMapView, annotationCanShowCallout annotation: MGLAnnotation) -> Bool {
            false
        }
        
        func mapView(_ mapView: MGLMapView, shouldChangeFrom oldCamera: MGLMapCamera, to newCamera: MGLMapCamera, reason: MGLCameraChangeReason) -> Bool {
            mapLibreView.userDidPan?()
            return true
        }
    }
}

// MARK: - MGLMapView convenient methods

private extension MGLMapView {
    func removeAllAnnotations() {
        guard let annotations else {
            return
        }
        removeAnnotations(annotations)
    }
}

private extension MapTilerStyle {
    init(_ colorScheme: ColorScheme) {
        switch colorScheme {
        case .light:
            self = .light
        case .dark:
            self = .dark
        @unknown default:
            fatalError()
        }
    }
}

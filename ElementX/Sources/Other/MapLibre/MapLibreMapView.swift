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
        /// The initial zoom level
        let zoomLevel: Double
        /// The initial map center
        let mapCenter: CLLocationCoordinate2D?
        /// Map annotations
        let annotations: [LocationAnnotation]

        init(zoomLevel: Double, mapCenter: CLLocationCoordinate2D? = nil, annotations: [LocationAnnotation] = []) {
            self.zoomLevel = zoomLevel
            self.mapCenter = mapCenter
            self.annotations = annotations
        }
    }
    
    // MARK: - Properties
    
    @Environment(\.colorScheme) private var colorScheme
    
    let builder: MapTilerStyleBuilderProtocol

    let options: Options
    
    /// Behavior mode of the current user's location, can be hidden, only shown and shown following the user
    var showsUserLocationMode: ShowUserLocationMode = .hide
    
    /// Bind view errors if any
    let error: Binding<MapLibreError?>
    
    /// Coordinate of the center of the map
    @Binding var mapCenterCoordinate: CLLocationCoordinate2D?

    /// Called when the user pan on the map
    var userDidPan: (() -> Void)?
    
    // MARK: - UIViewRepresentable
    
    func makeUIView(context: Context) -> MGLMapView {
        let mapView = makeMapView()
        mapView.delegate = context.coordinator
        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.didPan))
        panGesture.delegate = context.coordinator
        mapView.addGestureRecognizer(panGesture)
        setupMap(mapView: mapView, with: options)
        return mapView
    }
    
    func updateUIView(_ mapView: MGLMapView, context: Context) {
        mapView.removeAllAnnotations()
        mapView.addAnnotations(options.annotations)
        
        if colorScheme == .dark {
            mapView.styleURL = builder.dynamicMapURL(for: .dark)
        } else {
            mapView.styleURL = builder.dynamicMapURL(for: .light)
        }
        
        showUserLocation(in: mapView)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // MARK: - Private

    private func setupMap(mapView: MGLMapView, with options: Options) {
        mapView.zoomLevel = options.zoomLevel
        if let mapCenter = options.mapCenter {
            mapView.centerCoordinate = mapCenter
        }
    }
    
    private func makeMapView() -> MGLMapView {
        let mapView = MGLMapView(frame: .zero, styleURL: colorScheme == .dark ? builder.dynamicMapURL(for: .dark) : builder.dynamicMapURL(for: .light))
        
        showUserLocation(in: mapView)
        mapView.attributionButton.isHidden = true
        
        return mapView
    }
    
    private func showUserLocation(in mapView: MGLMapView) {
        switch showsUserLocationMode {
        case .showAndFollow:
            mapView.showsUserLocation = true
            mapView.userTrackingMode = .follow
        case .show:
            mapView.showsUserLocation = true
            mapView.userTrackingMode = .none
        case .hide:
            mapView.showsUserLocation = false
            mapView.userTrackingMode = .none
        }
    }
}

// MARK: - Coordinator

extension MapLibreMapView {
    class Coordinator: NSObject, MGLMapViewDelegate, UIGestureRecognizerDelegate {
        // MARK: - Properties

        var mapLibreView: MapLibreMapView
        
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
        
        func mapView(_ mapView: MGLMapView, didUpdate userLocation: MGLUserLocation?) { }
        
        func mapView(_ mapView: MGLMapView, didChangeLocationManagerAuthorization manager: MGLLocationManager) {
            guard mapView.showsUserLocation else {
                return
            }
            
            switch manager.authorizationStatus {
            case .denied, .restricted:
                mapLibreView.error.wrappedValue = .invalidLocationAuthorization
            default:
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
        
        // MARK: UIGestureRecognizer
        
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            gestureRecognizer is UIPanGestureRecognizer
        }
        
        @objc
        func didPan() {
            mapLibreView.userDidPan?()
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

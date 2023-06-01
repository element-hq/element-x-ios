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

/*
 Behavior mode of the current user's location, can be hidden, only shown and shown following the user
 */
enum ShowUserLocationMode {
    case follow
    case show
    case hide
}

struct LocationSharingMapView: UIViewRepresentable {
    // MARK: - Constants
    
    private enum Constants {
        static let mapZoomLevel = 15.0
    }
    
    // MARK: - Properties
    
    /// Map style URL (https://docs.mapbox.com/api/maps/styles/)
    let tileServerMapURL: URL
    
    /// Behavior mode of the current user's location, can be hidden, only shown and shown following the user
    var showsUserLocationMode: ShowUserLocationMode = .hide
    
    /// True to indicate that a touch on user annotation can show a callout
    var userAnnotationCanShowCallout = false

    /// Last user location if `showsUserLocation` has been enabled
    @Binding var userLocation: CLLocationCoordinate2D?
    
    /// Coordinate of the center of the map
    @Binding var mapCenterCoordinate: CLLocationCoordinate2D?
    
    /// Publish view errors if any
    let errorSubject: PassthroughSubject<LocationSharingViewError, Never>

    // MARK: - UIViewRepresentable
    
    func makeUIView(context: Context) -> MGLMapView {
        let mapView = makeMapView()
        mapView.delegate = context.coordinator
        return mapView
    }
    
    func updateUIView(_ mapView: MGLMapView, context: Context) {
        mapView.vc_removeAllAnnotations()
        
        switch showsUserLocationMode {
        case .follow:
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
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // MARK: - Private
    
    private func makeMapView() -> MGLMapView {
        let mapView = MGLMapView(frame: .zero, styleURL: tileServerMapURL)

        mapView.logoView.isHidden = true
        mapView.attributionButton.isHidden = true
        
        return mapView
    }
}

// MARK: - Coordinator

extension LocationSharingMapView {
    class Coordinator: NSObject, MGLMapViewDelegate, UIGestureRecognizerDelegate {
        // MARK: - Properties

        var locationSharingMapView: LocationSharingMapView
        
        // MARK: - Setup

        init(_ locationSharingMapView: LocationSharingMapView) {
            self.locationSharingMapView = locationSharingMapView
        }
        
        // MARK: - MGLMapViewDelegate
        
        func mapViewDidFailLoadingMap(_ mapView: MGLMapView, withError error: Error) {
            locationSharingMapView.errorSubject.send(.failedLoadingMap)
        }
        
        func mapView(_ mapView: MGLMapView, didUpdate userLocation: MGLUserLocation?) {
            locationSharingMapView.userLocation = userLocation?.coordinate
        }
        
        func mapView(_ mapView: MGLMapView, didChangeLocationManagerAuthorization manager: MGLLocationManager) {
            guard mapView.showsUserLocation else {
                return
            }
            
            switch manager.authorizationStatus {
            case .denied, .restricted:
                locationSharingMapView.errorSubject.send(.invalidLocationAuthorization)
            default:
                break
            }
        }
        
        func mapView(_ mapView: MGLMapView, regionDidChangeAnimated animated: Bool) {
            locationSharingMapView.mapCenterCoordinate = mapView.centerCoordinate
        }
        
        // MARK: Callout
                
        func mapView(_ mapView: MGLMapView, annotationCanShowCallout annotation: MGLAnnotation) -> Bool {
            locationSharingMapView.userAnnotationCanShowCallout
        }
        
        // MARK: UIGestureRecognizer
        
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            gestureRecognizer is UIPanGestureRecognizer
        }
    }
}

// MARK: - MGLMapView convenient methods

extension MGLMapView {
    func vc_removeAllAnnotations() {
        guard let annotations else {
            return
        }
        removeAnnotations(annotations)
    }
}

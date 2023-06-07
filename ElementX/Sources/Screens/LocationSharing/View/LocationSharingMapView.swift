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

struct LocationSharingMapView: UIViewRepresentable {
    // MARK: - Constants
    
    private enum Constants {
        static let mapZoomLevel = 15.0
    }
    
    // MARK: - Properties
    
    @Environment(\.colorScheme) var colorScheme
    
    var lightTileServerMapURL: URL {
        let appSettings = ServiceLocator.shared.settings!
        let key = appSettings.mapTilerApiKey
        return URL(string: appSettings.lightTileMapStyleURL + "?key=" + key)!
    }
    
    var darkTileServerMapURL: URL {
        let appSettings = ServiceLocator.shared.settings!
        let key = appSettings.mapTilerApiKey
        return URL(string: appSettings.darkTileMapStyleURL + "?key=" + key)!
    }
    
    /// Behavior mode of the current user's location, can be hidden, only shown and shown following the user
    var showsUserLocationMode: ShowUserLocationMode = .hide
    
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
        
        if colorScheme == .dark {
            mapView.styleURL = darkTileServerMapURL
        } else {
            mapView.styleURL = lightTileServerMapURL
        }
        
        showUserLocation(in: mapView)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // MARK: - Private
    
    private func makeMapView() -> MGLMapView {
        let mapView = MGLMapView(frame: .zero, styleURL: colorScheme == .dark ? darkTileServerMapURL : lightTileServerMapURL)

        mapView.logoView.isHidden = true
        mapView.attributionButton.isHidden = true
        mapView.zoomLevel = Constants.mapZoomLevel
        
        showUserLocation(in: mapView)
        
        return mapView
    }
    
    func showUserLocation(in mapView: MGLMapView) {
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
        
        func mapView(_ mapView: MGLMapView, viewFor annotation: MGLAnnotation) -> MGLAnnotationView? {
            if let pinLocationAnnotation = annotation as? PinLocationAnnotation {
                return LocationAnnotationView(pinLocationAnnotation: pinLocationAnnotation)
            } else if annotation is MGLUserLocation {
                return LocationAnnotationView(userPinLocationAnnotation: annotation)
            }
            return nil
        }
        
        func mapViewDidFailLoadingMap(_ mapView: MGLMapView, withError error: Error) {
            locationSharingMapView.errorSubject.send(.failedLoadingMap)
        }
        
        func mapView(_ mapView: MGLMapView, didUpdate userLocation: MGLUserLocation?) { }
        
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
        
        func mapView(_ mapView: MGLMapView, regionDidChangeAnimated animated: Bool) { }
        
        // MARK: Callout
                
        func mapView(_ mapView: MGLMapView, annotationCanShowCallout annotation: MGLAnnotation) -> Bool {
            false
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

//
// Copyright 2026 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import MapLibre
import MapLibreInterface
import SwiftUI

struct MapLibreMapView: UIViewRepresentable {
    // MARK: - Properties
    
    @Environment(\.colorScheme) private var colorScheme
    
    let configuration: MapViewConfiguration
    
    // MARK: - UIViewRepresentable
    
    func makeUIView(context: Context) -> MLNMapView {
        let mapView = makeMapView()
        mapView.delegate = context.coordinator
        setupMap(mapView: mapView)
        return mapView
    }
    
    func updateUIView(_ mapView: MLNMapView, context: Context) {
        // Don't set the same value twice. Otherwise, if there is an error loading the map, a loop
        // is caused as the `error` binding being set, which triggers this update, which sets a
        // new URL, which causes another error, and so it goes on round and round in a circle.
        let dynamicMapURL = configuration.styleURL(colorScheme == .dark)
        if mapView.styleURL != dynamicMapURL {
            mapView.styleURL = dynamicMapURL
        }
        
        // If the center coordinate was updated externally (not by the map itself), move the map.
        // Not applied while following a marker, where the camera is driven by the marker's position.
        if configuration.showsUserLocationMode.wrappedValue.followedMarkerID == nil,
           let newCenter = configuration.mapCenterCoordinate.wrappedValue,
           newCenter.latitude != context.coordinator.lastReportedCenter?.latitude
           || newCenter.longitude != context.coordinator.lastReportedCenter?.longitude {
            context.coordinator.lastReportedCenter = newCenter
            mapView.setCenter(newCenter, animated: true)
        }
        
        // Update existing annotation views with fresh SwiftUI content.
        // This handles the case where the annotation's view data changes after
        // the annotation was initially placed (e.g. user avatar loads asynchronously).
        updateAnnotations(in: mapView)
        
        showUserLocation(in: mapView)
        
        context.coordinator.updateMarkerFollowing(in: mapView, markerID: configuration.showsUserLocationMode.wrappedValue.followedMarkerID)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // MARK: - Private
    
    private func setupMap(mapView: MLNMapView) {
        mapView.addAnnotations(configuration.annotations.map(MapLibreAnnotation.init))
        mapView.zoomLevel = configuration.annotations.isEmpty ? configuration.initialZoomLevel : configuration.zoomLevel
        mapView.centerCoordinate = configuration.mapCenter
    }
    
    private func updateAnnotations(in mapView: MLNMapView) {
        let existingByID = Dictionary(uniqueKeysWithValues:
            (mapView.annotations ?? []).compactMap { $0 as? MapLibreAnnotation }.map { ($0.id, $0) })
        let updatedByID = Dictionary(uniqueKeysWithValues: configuration.annotations.map { ($0.id, $0) })
        
        let existingIDs = Set(existingByID.keys)
        let updatedIDs = Set(updatedByID.keys)
        
        // Remove annotations that are no longer present
        let removedIDs = existingIDs.subtracting(updatedIDs)
        if !removedIDs.isEmpty {
            let toRemove = removedIDs.compactMap { existingByID[$0] }
            mapView.removeAnnotations(toRemove)
        }
        
        // Add new annotations
        let addedIDs = updatedIDs.subtracting(existingIDs)
        if !addedIDs.isEmpty {
            let toAdd = addedIDs.compactMap { updatedByID[$0] }.map(MapLibreAnnotation.init)
            mapView.addAnnotations(toAdd)
        }
        
        // Update existing annotations that are still present
        let keptIDs = existingIDs.intersection(updatedIDs)
        for id in keptIDs {
            guard let existingAnnotation = existingByID[id],
                  let updatedAnnotation = updatedByID[id] else {
                continue
            }
            CoordinateAnimator.animate(annotation: existingAnnotation,
                                       to: updatedAnnotation.coordinate,
                                       duration: 1.0)
            if let annotationView = mapView.view(for: existingAnnotation) as? MapLibreAnnotationView {
                annotationView.updateContent(configuration.markerView(id))
            }
        }
    }
    
    private func makeMapView() -> MLNMapView {
        let mapView = MLNMapView(frame: .zero, styleURL: configuration.styleURL(colorScheme == .dark))
        mapView.logoViewPosition = .topLeft
        mapView.attributionButtonPosition = .topLeft
        mapView.attributionButtonMargins = .init(x: mapView.logoView.frame.maxX + 8, y: mapView.logoView.center.y / 2)
        mapView.tintColor = configuration.tintColor
        mapView.allowsRotating = false
        mapView.allowsTilting = false
        return mapView
    }
    
    private func showUserLocation(in mapView: MLNMapView) {
        switch (configuration.showsUserLocationMode.wrappedValue, configuration.annotations) {
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
        case (.hide, _), (.hideAndFollowMarker, _):
            // In hideAndFollowMarker mode the camera following is handled by the coordinator.
            mapView.showsUserLocation = false
            mapView.setUserTrackingMode(.none, animated: false, completionHandler: nil)
        }
    }
}

// MARK: - Coordinator

extension MapLibreMapView {
    class Coordinator: NSObject, MLNMapViewDelegate {
        // MARK: - Properties
        
        var mapLibreView: MapLibreMapView
        
        private var previousUserLocation: MLNUserLocation?
        /// Tracks the last center coordinate reported by the map (or set programmatically),
        /// so that `updateUIView` can tell apart external binding changes from internal ones.
        var lastReportedCenter: CLLocationCoordinate2D?
        
        /// The annotation the camera is currently locked on while in the `hideAndFollowMarker` mode.
        private weak var followedAnnotation: MapLibreAnnotation?
        /// Observes the followed annotation's coordinate, updated every frame by the `CoordinateAnimator`.
        private var followedAnnotationObservation: NSKeyValueObservation?
        
        // MARK: - Setup
        
        init(_ mapLibreView: MapLibreMapView) {
            self.mapLibreView = mapLibreView
        }
        
        // MARK: - Marker following
        
        /// Keeps the camera locked on the marker with the given id, or stops following when nil.
        func updateMarkerFollowing(in mapView: MLNMapView, markerID: String?) {
            guard let markerID else {
                stopFollowingMarker()
                return
            }
            
            guard let annotation = (mapView.annotations ?? [])
                .compactMap({ $0 as? MapLibreAnnotation })
                .first(where: { $0.id == markerID }) else {
                // The marker isn't on the map (yet), resolve it again on the next update.
                stopFollowingMarker()
                return
            }
            
            guard annotation !== followedAnnotation else { return }
            startFollowingMarker(annotation, in: mapView)
        }
        
        private func startFollowingMarker(_ annotation: MapLibreAnnotation, in mapView: MLNMapView) {
            followedAnnotation = annotation
            followedAnnotationObservation = nil
            
            // Animate to the marker first, attaching the per-frame tracking only on completion
            // so that it doesn't cancel the transition.
            mapView.setCenter(annotation.coordinate,
                              zoomLevel: mapView.zoomLevel,
                              direction: -1, // negative value keeps the current direction
                              animated: true) { [weak self, weak annotation, weak mapView] in
                guard let self, let annotation, let mapView, annotation === followedAnnotation else { return }
                
                // Mirror every animated coordinate update to keep the camera as smooth as the marker.
                followedAnnotationObservation = annotation.observe(\.coordinate) { [weak mapView] annotation, _ in
                    // The coordinate is only ever updated by SwiftUI so KVO fires on the main actor.
                    MainActor.assumeIsolated {
                        mapView?.setCenter(annotation.coordinate, animated: false)
                    }
                }
            }
        }
        
        private func stopFollowingMarker() {
            followedAnnotation = nil
            followedAnnotationObservation = nil
        }
        
        // MARK: - MLNMapViewDelegate
        
        func mapView(_ mapView: MLNMapView, viewFor annotation: MLNAnnotation) -> MLNAnnotationView? {
            guard let annotation = annotation as? MapLibreAnnotation else {
                return nil
            }
            return MapLibreAnnotationView(annotation: annotation, content: mapLibreView.configuration.markerView(annotation.id))
        }
        
        func mapViewDidFailLoadingMap(_ mapView: MLNMapView, withError error: Error) {
            if mapLibreView.configuration.error.wrappedValue != .failedLoadingMap {
                mapLibreView.configuration.error.wrappedValue = .failedLoadingMap
            }
        }
        
        func mapView(_ mapView: MLNMapView, didUpdate userLocation: MLNUserLocation?) {
            guard let userLocation else { return }
            mapLibreView.configuration.hasLoadedUserLocation.wrappedValue = true
            
            if previousUserLocation == nil, mapLibreView.configuration.annotations.isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    mapView.setCenter(userLocation.coordinate, zoomLevel: self.mapLibreView.configuration.zoomLevel, animated: true)
                }
            }
            
            previousUserLocation = userLocation
            updateGeolocationUncertainty(location: userLocation)
        }
        
        func mapView(_ mapView: MLNMapView, didChangeLocationManagerAuthorization manager: MLNLocationManager) {
            switch manager.authorizationStatus {
            case .denied, .restricted:
                mapLibreView.configuration.isLocationAuthorized.wrappedValue = false
            case .authorizedAlways, .authorizedWhenInUse:
                mapLibreView.configuration.isLocationAuthorized.wrappedValue = true
            case .notDetermined:
                mapLibreView.configuration.isLocationAuthorized.wrappedValue = nil
            @unknown default:
                break
            }
        }
        
        func mapView(_ mapView: MLNMapView, regionDidChangeAnimated animated: Bool) {
            // While following a marker, don't flood the center binding with per-frame camera updates.
            // Leaving `lastReportedCenter` untouched avoids an external re-centering when following stops.
            guard mapLibreView.configuration.showsUserLocationMode.wrappedValue.followedMarkerID == nil else { return }
            
            // Avoid `Publishing changes from within view update` warnings
            DispatchQueue.main.async { [mapLibreView, weak self] in
                let center = mapView.centerCoordinate
                self?.lastReportedCenter = center
                mapLibreView.configuration.mapCenterCoordinate.wrappedValue = center
            }
        }
        
        func mapView(_ mapView: MLNMapView, shouldChangeFrom oldCamera: MLNMapCamera, to newCamera: MLNMapCamera, reason: MLNCameraChangeReason) -> Bool {
            // Send userDidPan only for gestures that actually change the map center. The reason
            // is an option set and gestures can come combined with other reasons, so check for
            // containment instead of an exact match.
            let centerChangingGestures: MLNCameraChangeReason = [.gesturePan, .gesturePinch, .gestureRotate]
            if !reason.isDisjoint(with: centerChangingGestures) {
                // Stop following immediately, the camera would fight the gesture otherwise.
                stopFollowingMarker()
                mapLibreView.configuration.userDidPan?()
            }
            return true
        }
        
        // MARK: Callout
        
        func mapView(_ mapView: MLNMapView, annotationCanShowCallout annotation: MLNAnnotation) -> Bool {
            false
        }
        
        // MARK: Private
        
        private func updateGeolocationUncertainty(location: MLNUserLocation) {
            guard let clLocation = location.location, clLocation.horizontalAccuracy >= 0 else {
                mapLibreView.configuration.geolocationUncertainty.wrappedValue = nil
                return
            }
            
            mapLibreView.configuration.geolocationUncertainty.wrappedValue = clLocation.horizontalAccuracy
        }
    }
}

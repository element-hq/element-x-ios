//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import CoreLocation

/// Owns the app's only `CLLocationManager`. Runs location updates while any account's `LiveLocationService`
/// is sharing, hands each location to those services and keeps their authorization status up to date.
final class LiveLocationManager: NSObject, LiveLocationManagerProtocol, CLLocationManagerDelegate {
    private let locationManager: CLLocationManagerProtocol
    private let appSettings: AppSettings
    
    private var services: [String: LiveLocationServiceProtocol] = [:]
    private var serviceCancellables: [String: Set<AnyCancellable>] = [:]
    private var cancellables = Set<AnyCancellable>()
    
    private var isUpdatingLocation = false
    /// The latest location while updates run, handed to an account as soon as it starts sharing.
    private var lastLocation: CLLocationCoordinate2D?
    
    private var isAnyAccountSharing: Bool {
        services.values.contains { $0.isSharingPublisher.value }
    }
    
    init(appSettings: AppSettings,
         locationManager: @autoclosure @MainActor () -> CLLocationManagerProtocol = CLLocationManager()) {
        self.appSettings = appSettings
        // Very important, the CLLocationManager needs to be initialised on the main thread
        // or the delegate functions won't be handled!
        // https://developer.apple.com/documentation/corelocation/cllocationmanagerdelegate
        self.locationManager = locationManager()
        
        super.init()
        
        // Configure CLLocationManager for continuous background tracking.
        self.locationManager.delegate = self
        self.locationManager.allowsBackgroundLocationUpdates = true
        self.locationManager.showsBackgroundLocationIndicator = true
        
        // Since unpausing location updates is not trivial, let's always keep the location updates running
        // The distance filtering will already take care of not sending updates when not required.
        // https://developer.apple.com/documentation/corelocation/cllocationmanager/pauseslocationupdatesautomatically
        self.locationManager.pausesLocationUpdatesAutomatically = false
        
        setupMinimumDistanceUpdatesAndAccuracy(minimumDistance: appSettings.liveLocationMinimumDistanceUpdate)
        setupSubscriptions()
    }
    
    // MARK: - LiveLocationManagerProtocol
    
    func add(_ service: LiveLocationServiceProtocol) {
        let userID = service.userID
        services[userID] = service
        service.authorizationStatusChanged(to: locationManager.authorizationStatus)
        
        serviceCancellables[userID] = [
            service.actionsPublisher.sink { [weak self] action in
                self?.process(action)
            },
            service.isSharingPublisher
                .removeDuplicates()
                .sink { [weak self] isSharing in
                    self?.isSharingChanged(isSharing, for: userID)
                }
        ]
        
        // Shares restored without the authorization they need can't carry on.
        if locationManager.authorizationStatus != .authorizedAlways {
            Task { await service.stopAllLiveLocations() }
        }
    }
    
    func remove(userID: String) {
        serviceCancellables[userID] = nil
        guard services.removeValue(forKey: userID) != nil else { return }
        syncLocationUpdates()
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let authorizationStatus = locationManager.authorizationStatus
        
        // If the system resets authorization to notDetermined (e.g. after app reinstall or
        // settings reset), clear the flag so we can request again.
        if authorizationStatus == .notDetermined {
            appSettings.hasRequestedLocationAlwaysLocationAuthorization = false
        }
        
        // If authorization was revoked, stop all active sessions.
        if authorizationStatus != .authorizedAlways {
            stopAllLiveLocations()
        }
        
        // Accuracy authorization may have changed, reapply new accuracy settings.
        setupMinimumDistanceUpdatesAndAccuracy(minimumDistance: appSettings.liveLocationMinimumDistanceUpdate)
        
        for service in services.values {
            service.authorizationStatusChanged(to: authorizationStatus)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let coordinate = locations.last?.coordinate else { return }
        
        MXLog.verbose("Received location update via delegate, sending to rooms")
        lastLocation = coordinate
        for service in services.values where service.isSharingPublisher.value {
            service.locationUpdated(coordinate)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Core Location keeps trying after this one, so the shares can carry on.
        if (error as? CLError)?.code == .locationUnknown {
            MXLog.info("Location manager couldn't find the location yet")
            return
        }
        
        MXLog.error("Location manager failed with error: \(error)")
        stopAllLiveLocations()
    }
    
    // MARK: - Private
    
    private func setupSubscriptions() {
        appSettings.liveLocationMinimumDistanceUpdatePublisher
            .removeDuplicates()
            .debounce(for: .seconds(1), scheduler: DispatchQueue.main)
            .sink { [weak self] newValue in
                self?.setupMinimumDistanceUpdatesAndAccuracy(minimumDistance: newValue)
            }
            .store(in: &cancellables)
    }
    
    private func process(_ action: LiveLocationServiceAction) {
        switch action {
        case .requestAlwaysAuthorization:
            appSettings.hasRequestedLocationAlwaysLocationAuthorization = true
            locationManager.requestAlwaysAuthorization()
        }
    }
    
    private func isSharingChanged(_ isSharing: Bool, for userID: String) {
        // A share that starts while updates already run gets the latest location straight away.
        if isSharing, let lastLocation {
            services[userID]?.locationUpdated(lastLocation)
        }
        syncLocationUpdates()
    }
    
    private func syncLocationUpdates() {
        if isAnyAccountSharing {
            startUpdatingLocation()
        } else {
            stopUpdatingLocation()
        }
    }
    
    private func stopAllLiveLocations() {
        let services = Array(services.values)
        Task {
            for service in services {
                await service.stopAllLiveLocations()
            }
        }
    }
    
    /// Sets up the distance filter and the most optimal accuracy given the minimum distance to save battery.
    private func setupMinimumDistanceUpdatesAndAccuracy(minimumDistance: Int) {
        if locationManager.accuracyAuthorization == .fullAccuracy {
            switch minimumDistance {
            case 0..<10:
                locationManager.desiredAccuracy = kCLLocationAccuracyBest
            case 10..<100:
                locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            default:
                locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
            }
        } else {
            locationManager.desiredAccuracy = kCLLocationAccuracyReduced
        }
        locationManager.distanceFilter = CLLocationDistance(minimumDistance)
    }
    
    private func startUpdatingLocation() {
        guard !isUpdatingLocation else { return }
        
        MXLog.info("Starting live location updates")
        isUpdatingLocation = true
        locationManager.startUpdatingLocation()
    }
    
    private func stopUpdatingLocation() {
        guard isUpdatingLocation else { return }
        
        MXLog.info("Stopping live location updates")
        locationManager.stopUpdatingLocation()
        isUpdatingLocation = false
        lastLocation = nil
    }
}

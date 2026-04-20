//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import CoreLocation

class LiveLocationManager: NSObject, LiveLocationManagerProtocol, CLLocationManagerDelegate {
    enum LiveState {
        case full
        case limited
        case off
    }
    
    private let clientProxy: ClientProxyProtocol
    private let locationManager: CLLocationManagerProtocol
    private let appSettings: AppSettings
    
    private let authorizationStatusSubject: CurrentValueSubject<CLAuthorizationStatus, Never>
    var authorizationStatus: CurrentValuePublisher<CLAuthorizationStatus, Never> {
        authorizationStatusSubject.asCurrentValuePublisher()
    }
    
    /// Cached joined room proxies keyed by room ID, kept in sync with the active sessions dictionary.
    private var activeRoomProxies = [String: JoinedRoomProxyProtocol]()
    
    /// Subject used to pipe location updates through Combine's throttle operator.
    private let locationUpdateSubject = PassthroughSubject<CLLocationCoordinate2D, Never>()
    
    private var cancellables = Set<AnyCancellable>()
    
    private var liveState = LiveState.off
    
    @MainActor
    init(clientProxy: ClientProxyProtocol,
         appSettings: AppSettings,
         locationManager: @autoclosure @MainActor () -> CLLocationManagerProtocol = CLLocationManager()) {
        self.clientProxy = clientProxy
        self.appSettings = appSettings
        // Very important, the CLLocationManager needs to be initialised on the main thread
        // or the delegate functions won't be handled!
        // https://developer.apple.com/documentation/corelocation/cllocationmanagerdelegate
        self.locationManager = locationManager()
        authorizationStatusSubject = CurrentValueSubject(self.locationManager.authorizationStatus)
        
        super.init()
        
        // Configure CLLocationManager for continuous background tracking.
        self.locationManager.delegate = self
        self.locationManager.allowsBackgroundLocationUpdates = true
        self.locationManager.showsBackgroundLocationIndicator = true
        setupMinimumDistance(appSettings.liveLocationMinimumDistanceUpdate)
        setupSubscriptions()
    }

    // MARK: - LiveLocationManagerProtocol
    
    @discardableResult
    func requestAlwaysAuthorizationIfPossible() -> Bool {
        guard !appSettings.hasRequestedLocationAlwaysLocationAuthorization else { return false }
        appSettings.hasRequestedLocationAlwaysLocationAuthorization = true
        locationManager.requestAlwaysAuthorization()
        return true
    }
    
    func startLiveLocation(roomID: String, duration: Duration) async -> Result<Void, LiveLocationManagerError> {
        // Stop any existing session for this room first (e.g. one started from a different device)
        // before starting a new one.
        if appSettings.liveLocationSharingTimeoutDatesByRoomID[roomID] != nil {
            await stopLiveLocation(roomID: roomID)
        }
        
        guard case .joined(let roomProxy) = await clientProxy.roomForIdentifier(roomID) else {
            MXLog.error("Failed to resolve joined room for identifier: \(roomID)")
            return .failure(.roomNotJoined)
        }
        
        let result = await roomProxy.startLiveLocationShare(duration: duration)
        
        guard case .success = result else {
            MXLog.error("Failed to start live location share in room: \(roomID)")
            return .failure(.startFailed)
        }
        
        let timeoutDate = Date().addingTimeInterval(TimeInterval(duration.seconds))
        appSettings.liveLocationSharingTimeoutDatesByRoomID[roomID] = timeoutDate
        
        return .success(())
    }
    
    func stopLiveLocation(roomID: String) async {
        var roomProxy: JoinedRoomProxyProtocol?
        let cachedRoomProxy = activeRoomProxies[roomID]
        appSettings.liveLocationSharingTimeoutDatesByRoomID.removeValue(forKey: roomID)
        
        if let cachedRoomProxy {
            roomProxy = cachedRoomProxy
            // Best effort: send the stop event to the room regardless of tracking state.
        } else if case let .joined(fetchedRoomProxy) = await clientProxy.roomForIdentifier(roomID) {
            roomProxy = fetchedRoomProxy
        }
        
        if let roomProxy {
            let result = await roomProxy.stopLiveLocationShare()
            if case .failure(let error) = result {
                MXLog.error("Failed to stop live location share in room \(roomID): \(error)")
            }
        }
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        // If the system resets authorization to notDetermined (e.g. after app reinstall or
        // settings reset), clear the flag so we can request again.
        if manager.authorizationStatus == .notDetermined {
            appSettings.hasRequestedLocationAlwaysLocationAuthorization = false
        }
        
        // If authorization was revoked, stop all active sessions.
        if manager.authorizationStatus != .authorizedAlways {
            stopAllSessions()
        }
        
        switch (liveState, manager.accuracyAuthorization) {
        // If accuracy authorization changed while updates are active, start and stop to switch update method.
        case (.full, .reducedAccuracy), (.limited, .fullAccuracy):
            stopUpdatingLocation()
            if manager.accuracyAuthorization == .fullAccuracy {
                // The system has forced reduced desired accuracy so we need to restore the desired value by the user.
                setupMinimumDistance(appSettings.liveLocationMinimumDistanceUpdate)
            }
            startUpdatingLocation()
        default:
            break
        }
        
        authorizationStatusSubject.send(manager.authorizationStatus)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        MXLog.verbose("Received location update via delegate, sending to rooms")
        locationUpdateSubject.send(location.coordinate)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        MXLog.error("Location manager failed with error: \(error)")
        stopAllSessions()
    }
    
    // MARK: - Private
    
    private func setupSubscriptions() {
        locationUpdateSubject
            .throttle(for: .seconds(3), scheduler: DispatchQueue.main, latest: true)
            .sink { [weak self] update in
                guard let self else { return }
                guard !appSettings.liveLocationSharingTimeoutDatesByRoomID.isEmpty else { return }
                Task { [weak self] in
                    await self?.sendLocationToActiveRooms(update)
                }
            }
            .store(in: &cancellables)
        
        appSettings.$liveLocationSharingTimeoutDatesByRoomID
            .removeDuplicates()
            .sink { [weak self] sessions in
                guard let self else { return }
                syncActiveRoomProxies(with: sessions)
                
                if sessions.isEmpty {
                    self.stopUpdatingLocation()
                } else {
                    self.startUpdatingLocation()
                }
            }
            .store(in: &cancellables)
        
        appSettings.$liveLocationSharingEnabled
            .filter { !$0 }
            .sink { [weak self] _ in
                guard let self else { return }
                appSettings.liveLocationSharingTimeoutDatesByRoomID.removeAll()
                activeRoomProxies.removeAll()
                self.stopUpdatingLocation()
            }
            .store(in: &cancellables)
        
        appSettings.$liveLocationMinimumDistanceUpdate
            .removeDuplicates()
            .debounce(for: .seconds(1), scheduler: DispatchQueue.main)
            .sink { [weak self] minimumDistance in
                self?.setupMinimumDistance(minimumDistance)
            }
            .store(in: &cancellables)
    }
    
    private func syncActiveRoomProxies(with sessions: [String: Date]) {
        // Remove proxies for rooms no longer in the dictionary.
        let activeRoomIDs = Set(sessions.keys)
        for roomID in activeRoomProxies.keys where !activeRoomIDs.contains(roomID) {
            activeRoomProxies.removeValue(forKey: roomID)
        }
    }
    
    /// Sets up the distance filter and the most optimal accuracy given the minimum distance to save battery.
    private func setupMinimumDistance(_ minimumDistance: Int) {
        switch minimumDistance {
        case 0..<10:
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
        case 10..<100:
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        default:
            locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        }
        locationManager.distanceFilter = CLLocationDistance(minimumDistance)
    }
    
    private func startUpdatingLocation() {
        guard liveState == .off else { return }
        
        if locationManager.accuracyAuthorization == .fullAccuracy {
            MXLog.info("Starting live location updates with full accuracy")
            liveState = .full
            locationManager.startUpdatingLocation()
        } else {
            MXLog.info("Starting live location updates with significant changes (reduced accuracy)")
            liveState = .limited
            locationManager.startMonitoringSignificantLocationChanges()
        }
    }
    
    private func stopUpdatingLocation() {
        if liveState == .full {
            MXLog.info("Stopping live location updates (full accuracy)")
            locationManager.stopUpdatingLocation()
        } else if liveState == .limited {
            MXLog.info("Stopping live location updates (reduced accuracy)")
            locationManager.stopMonitoringSignificantLocationChanges()
        }
        
        liveState = .off
    }
    
    private func sendLocationToActiveRooms(_ coordinate: CLLocationCoordinate2D) async {
        let sessions = appSettings.liveLocationSharingTimeoutDatesByRoomID
        let geoURI = GeoURI(coordinate: coordinate, uncertainty: nil)
        
        for (roomID, timeoutDate) in sessions {
            if Date() >= timeoutDate {
                MXLog.info("Live location session expired for room: \(roomID)")
                await stopLiveLocation(roomID: roomID)
                continue
            }
            
            let roomProxy = await resolveRoomProxy(for: roomID)
            guard let roomProxy else {
                MXLog.error("Failed to resolve room proxy for live location update in room: \(roomID)")
                continue
            }
            
            switch await roomProxy.sendLiveLocation(geoURI: geoURI) {
            case .success:
                MXLog.debug("Sent live location to room: \(roomID)")
            case .failure(let error):
                MXLog.error("Failed to send live location update to room \(roomID): \(error)")
            }
        }
    }
    
    private func resolveRoomProxy(for roomID: String) async -> JoinedRoomProxyProtocol? {
        if let cached = activeRoomProxies[roomID] {
            return cached
        }
        
        guard case .joined(let roomProxy) = await clientProxy.roomForIdentifier(roomID) else {
            return nil
        }
        
        activeRoomProxies[roomID] = roomProxy
        return roomProxy
    }
    
    private func stopAllSessions() {
        let roomIDs = Array(appSettings.liveLocationSharingTimeoutDatesByRoomID.keys)
        Task { [weak self] in
            guard let self else { return }
            for roomID in roomIDs {
                await stopLiveLocation(roomID: roomID)
            }
        }
    }
}

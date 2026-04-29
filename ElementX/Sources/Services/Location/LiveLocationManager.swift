//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import CoreLocation

class LiveLocationManager: NSObject, LiveLocationManagerProtocol, CLLocationManagerDelegate {
    private let clientProxy: ClientProxyProtocol
    private let locationManager: CLLocationManagerProtocol
    private let appSettings: AppSettings
    
    private let authorizationStatusSubject: CurrentValueSubject<CLAuthorizationStatus, Never>
    var authorizationStatus: CurrentValuePublisher<CLAuthorizationStatus, Never> {
        authorizationStatusSubject.asCurrentValuePublisher()
    }
    
    /// Cached joined room proxies keyed by room ID, kept in sync with the active sessions dictionary.
    private var activeRoomProxies = [String: JoinedRoomProxyProtocol]()

    /// Sessions that have been requested but not yet confirmed by the server echo.
    /// Once the server acknowledges the beacon info, sessions are promoted to the persistent store.
    private var startingLiveLocationSharingSessionsByRoomID = [String: LiveLocationSession]()

    /// Subject used to pipe location updates into the backpressure-aware processing loop.
    private let locationUpdateSubject = PassthroughSubject<CLLocationCoordinate2D, Never>()

    /// The most recent location update waiting to be sent. When a send is already in progress,
    /// new updates overwrite this value so only the latest is sent once the current send completes.
    private var latestPendingLocation: CLLocationCoordinate2D?

    /// Whether a location send cycle (send + minimum delay) is currently in progress.
    private var isProcessingLocationUpdate = false

    private var cancellables = Set<AnyCancellable>()
    
    private var isUpdatingLocation = false
    
    private var lastLocation: CLLocationCoordinate2D?
    
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
        
        // Since unpausing location updates is not trivial, let's always keep the location updates running
        // The distance filtering will already take care of not sending updates when not required.
        // https://developer.apple.com/documentation/corelocation/cllocationmanager/pauseslocationupdatesautomatically
        self.locationManager.pausesLocationUpdatesAutomatically = false
        
        setupMinimumDistanceUpdatesAndAccuracy(minimumDistance: appSettings.liveLocationMinimumDistanceUpdate)
        setupSubscriptions()
    }

    // MARK: - LiveLocationManagerProtocol
    
    var hasDisplayedLiveLocationDisclaimer: Bool {
        get {
            appSettings.liveLocationDisclaimerDisplayed
        }
        set {
            appSettings.liveLocationDisclaimerDisplayed = newValue
        }
    }
    
    @discardableResult
    func requestAlwaysAuthorizationIfPossible() -> Bool {
        guard !appSettings.hasRequestedLocationAlwaysLocationAuthorization else { return false }
        appSettings.hasRequestedLocationAlwaysLocationAuthorization = true
        locationManager.requestAlwaysAuthorization()
        return true
    }
    
    func startLiveLocation(roomID: String, duration: Duration) async -> Result<Void, LiveLocationManagerError> {
        // Stop any existing session for this room first
        var didAlreadyStopLocalSession = false
        if appSettings.liveLocationSharingSessionsByRoomID[roomID] != nil
            || startingLiveLocationSharingSessionsByRoomID[roomID] != nil {
            await stopLiveLocation(roomID: roomID)
            didAlreadyStopLocalSession = true
        }
        
        guard case .joined(let roomProxy) = await clientProxy.roomForIdentifier(roomID) else {
            MXLog.error("Failed to resolve joined room for identifier: \(roomID)")
            return .failure(.roomNotJoined)
        }
        
        if !didAlreadyStopLocalSession {
            // In case an existing session has been started from another device, let's try to stop it.
            // It's a best effort thing, so we don't care if no session is present or if it fails.
            _ = await roomProxy.stopLiveLocationShare()
        }
        let result = await roomProxy.startLiveLocationShare(duration: duration)
        
        guard case .success(let eventID) = result else {
            MXLog.error("Failed to start live location share in room: \(roomID)")
            return .failure(.startFailed)
        }
        
        let expirationDate = Date().addingTimeInterval(TimeInterval(duration.seconds))
        startingLiveLocationSharingSessionsByRoomID[roomID] = LiveLocationSession(eventID: eventID, expirationDate: expirationDate)

        return .success(())
    }
    
    func stopLiveLocation(roomID: String) async {
        var roomProxy: JoinedRoomProxyProtocol?
        let cachedRoomProxy = activeRoomProxies[roomID]
        startingLiveLocationSharingSessionsByRoomID.removeValue(forKey: roomID)
        appSettings.liveLocationSharingSessionsByRoomID.removeValue(forKey: roomID)
        
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
        
        // Accuracy authorization may have changed, reapply new accuracy settings.
        setupMinimumDistanceUpdatesAndAccuracy(minimumDistance: appSettings.liveLocationMinimumDistanceUpdate)
        
        authorizationStatusSubject.send(manager.authorizationStatus)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        MXLog.verbose("Received location update via delegate, sending to rooms")
        locationUpdateSubject.send(location.coordinate)
        lastLocation = location.coordinate
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        MXLog.error("Location manager failed with error: \(error)")
        stopAllSessions()
    }
    
    // MARK: - Private
    
    private func setupSubscriptions() {
        locationUpdateSubject
            .sink { [weak self] update in
                guard let self else { return }
                latestPendingLocation = update
                processLocationUpdateIfNeeded()
            }
            .store(in: &cancellables)
        
        clientProxy.ownBeaconInfoUpdatesPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] update in
                guard let self else { return }
                handleBeaconInfoUpdate(update)
            }
            .store(in: &cancellables)

        appSettings.$liveLocationSharingSessionsByRoomID
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
        
        appSettings.$liveLocationMinimumDistanceUpdate
            .removeDuplicates()
            .debounce(for: .seconds(1), scheduler: DispatchQueue.main)
            .sink { [weak self] newValue in
                self?.setupMinimumDistanceUpdatesAndAccuracy(minimumDistance: newValue)
            }
            .store(in: &cancellables)
    }
    
    private func handleBeaconInfoUpdate(_ update: OwnBeaconInfoUpdate) {
        // A new beaconInfo has been received in a room with existing active session
        // This is either a new start or a new stop from a different device, so we
        // should remove the session from the current local one.
        if appSettings.liveLocationSharingSessionsByRoomID[update.roomID] != nil {
            appSettings.liveLocationSharingSessionsByRoomID.removeValue(forKey: update.roomID)
        }

        // Instead if we receive a new isLiveUpdate
        guard update.isLive else { return }

        // That belongs to a session that is starting in a room and matches the eventID
        guard let session = startingLiveLocationSharingSessionsByRoomID[update.roomID],
              session.eventID == update.eventID else {
            return
        }

        // This means the server has echoed the start of the session and we can safely promote it
        // to a started session and start sending live locations.
        startingLiveLocationSharingSessionsByRoomID.removeValue(forKey: update.roomID)
        appSettings.liveLocationSharingSessionsByRoomID[update.roomID] = session

        if isUpdatingLocation, let lastLocation {
            locationUpdateSubject.send(lastLocation)
        }
    }

    private func syncActiveRoomProxies(with sessions: [String: LiveLocationSession]) {
        // Remove proxies for rooms no longer in the dictionary.
        let activeRoomIDs = Set(sessions.keys)
        for roomID in activeRoomProxies.keys where !activeRoomIDs.contains(roomID) {
            activeRoomProxies.removeValue(forKey: roomID)
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
    
    /// Kicks off a send cycle if one isn't already running. Each cycle:
    /// 1. Takes the latest pending location and clears it.
    /// 2. Sends the location to all active rooms **and** waits a minimum 3-second delay (in parallel).
    /// 3. After both complete, checks for a new pending location and loops if one exists.
    /// This ensures at least 3 seconds or the send duration itself between consecutive sends,
    /// discarding any intermediate updates while always keeping the last one.
    private func processLocationUpdateIfNeeded() {
        guard !isProcessingLocationUpdate, let location = latestPendingLocation else { return }
        guard !appSettings.liveLocationSharingSessionsByRoomID.isEmpty else { return }

        latestPendingLocation = nil
        isProcessingLocationUpdate = true

        Task { @MainActor [weak self] in
            guard let self else { return }
            
            // Wait for both the send and the minimum throttle interval.
            // This guarantees at least 3 seconds between sends, plus the full send duration.
            await withTaskGroup(of: Void.self) { group in
                group.addTask { [weak self] in
                    await self?.sendLocationToActiveRooms(location)
                }
                group.addTask {
                    try? await Task.sleep(for: .seconds(3))
                }
            }
            
            isProcessingLocationUpdate = false
            processLocationUpdateIfNeeded()
        }
    }

    private func sendLocationToActiveRooms(_ coordinate: CLLocationCoordinate2D) async {
        let sessions = appSettings.liveLocationSharingSessionsByRoomID
        let geoURI = GeoURI(coordinate: coordinate, uncertainty: nil)
        
        for (roomID, session) in sessions {
            if Date() >= session.expirationDate {
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
                switch error {
                case .liveLocationSessionIsNotActive:
                    MXLog.error("Failed to send live location update to room \(roomID): session not active")
                    await stopLiveLocation(roomID: roomID)
                default:
                    MXLog.error("Failed to send live location update to room \(roomID): \(error)")
                }
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
        let roomIDs = Array(Set(appSettings.liveLocationSharingSessionsByRoomID.keys)
            .union(startingLiveLocationSharingSessionsByRoomID.keys))
        Task { [weak self] in
            guard let self else { return }
            for roomID in roomIDs {
                await stopLiveLocation(roomID: roomID)
            }
        }
    }
}

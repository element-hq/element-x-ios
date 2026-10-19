//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import CoreLocation

/// Shares one account's live location: starts and stops its shares and sends the locations the
/// `LiveLocationManager` hands it to the rooms it's sharing in.
final class LiveLocationService: LiveLocationServiceProtocol {
    private let clientProxy: ClientProxyProtocol
    private let userSettings: UserSettings
    private let timeProvider: TimeProvider
    
    private let actionsSubject = PassthroughSubject<LiveLocationServiceAction, Never>()
    var actionsPublisher: AnyPublisher<LiveLocationServiceAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    private let isSharingSubject: CurrentValueSubject<Bool, Never>
    var isSharingPublisher: CurrentValuePublisher<Bool, Never> {
        isSharingSubject.asCurrentValuePublisher()
    }
    
    private let authorizationStatusSubject = CurrentValueSubject<CLAuthorizationStatus, Never>(.notDetermined)
    var authorizationStatus: CurrentValuePublisher<CLAuthorizationStatus, Never> {
        authorizationStatusSubject.asCurrentValuePublisher()
    }
    
    var userID: String {
        clientProxy.userID
    }
    
    /// Cached joined room proxies keyed by room ID, kept in sync with the active sessions dictionary.
    private var activeRoomProxies = [String: JoinedRoomProxyProtocol]()
    
    /// Sessions that have been requested but not yet confirmed by the server echo.
    /// Once the server acknowledges the beacon info, sessions are promoted to the persistent store.
    private var startingLiveLocationSharingSessionsByRoomID = [String: LiveLocationSession]()
    
    /// The most recent location update waiting to be sent. When a send is already in progress,
    /// new updates overwrite this value so only the latest is sent once the current send completes.
    private var latestPendingLocation: CLLocationCoordinate2D?
    
    /// Whether a location send cycle (send + minimum delay) is currently in progress.
    private var isProcessingLocationUpdate = false
    
    private var lastLocation: CLLocationCoordinate2D?
    
    /// Stops the next share to expire. A phone that doesn't move gets no location updates to notice it.
    @CancellableTask private var expiryTask: Task<Void, Never>?
    
    private var cancellables = Set<AnyCancellable>()
    
    init(clientProxy: ClientProxyProtocol, userSettings: UserSettings, timeProvider: TimeProvider? = nil) {
        self.clientProxy = clientProxy
        self.userSettings = userSettings
        self.timeProvider = timeProvider ?? TimeProvider(clock: ContinuousClock(), now: Date.init)
        isSharingSubject = .init(!userSettings.account.liveLocationSharingSessionsByRoomID.isEmpty)
        
        // Before subscribing, so shares that expired while the app wasn't running never count as sharing.
        stopExpiredLiveLocations()
        setupSubscriptions()
    }
    
    // MARK: - LiveLocationServiceProtocol
    
    @discardableResult
    func requestAlwaysAuthorizationIfPossible() -> Bool {
        guard !userSettings.app.hasRequestedLocationAlwaysLocationAuthorization else { return false }
        actionsSubject.send(.requestAlwaysAuthorization)
        return true
    }
    
    func startLiveLocation(roomID: String, duration: Duration) async -> Result<Void, LiveLocationServiceError> {
        // Stop any existing session for this room first
        var didAlreadyStopLocalSession = false
        if userSettings.account.liveLocationSharingSessionsByRoomID[roomID] != nil
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
        
        let expirationDate = timeProvider.now().addingTimeInterval(TimeInterval(duration.seconds))
        startingLiveLocationSharingSessionsByRoomID[roomID] = LiveLocationSession(eventID: eventID, expirationDate: expirationDate)
        
        return .success(())
    }
    
    func stopLiveLocation(roomID: String) async {
        var roomProxy: JoinedRoomProxyProtocol?
        let cachedRoomProxy = activeRoomProxies[roomID]
        startingLiveLocationSharingSessionsByRoomID.removeValue(forKey: roomID)
        userSettings.account.liveLocationSharingSessionsByRoomID.removeValue(forKey: roomID)
        
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
    
    func authorizationStatusChanged(to status: CLAuthorizationStatus) {
        authorizationStatusSubject.send(status)
    }
    
    func locationUpdated(_ coordinate: CLLocationCoordinate2D) {
        lastLocation = coordinate
        latestPendingLocation = coordinate
        processLocationUpdateIfNeeded()
    }
    
    func stopAllLiveLocations() async {
        let roomIDs = Set(userSettings.account.liveLocationSharingSessionsByRoomID.keys)
            .union(startingLiveLocationSharingSessionsByRoomID.keys)
        for roomID in roomIDs {
            await stopLiveLocation(roomID: roomID)
        }
    }
    
    // MARK: - Private
    
    private func setupSubscriptions() {
        clientProxy.liveLocationOwnInfoUpdatesPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] update in
                guard let self else { return }
                handleBeaconInfoUpdate(update)
            }
            .store(in: &cancellables)
        
        userSettings.account.liveLocationSharingSessionsByRoomIDPublisher
            .removeDuplicates()
            .sink { [weak self] sessions in
                guard let self else { return }
                syncActiveRoomProxies(with: sessions)
                scheduleExpiry(of: sessions)
                
                if sessions.isEmpty {
                    lastLocation = nil
                }
                isSharingSubject.send(!sessions.isEmpty)
            }
            .store(in: &cancellables)
    }
    
    private func handleBeaconInfoUpdate(_ update: LiveLocationOwnInfoUpdate) {
        // A new beaconInfo has been received in a room with existing active session.
        // This is either a new start or a new stop from a different device, so we
        // should remove the session from the current local one.
        userSettings.account.liveLocationSharingSessionsByRoomID.removeValue(forKey: update.roomID)
        
        // Instead if we receive a new isLiveUpdate
        guard update.isLive else { return }
        
        // That belongs to a session that is starting in a room and matches the eventID
        guard let session = startingLiveLocationSharingSessionsByRoomID[update.roomID],
              session.eventID == update.eventID else {
            return
        }
        
        // This means the server has echoed the start of the session and we can safely promote it
        // to a started session and start sending live locations.
        let wasSharing = isSharingSubject.value
        startingLiveLocationSharingSessionsByRoomID.removeValue(forKey: update.roomID)
        userSettings.account.liveLocationSharingSessionsByRoomID[update.roomID] = session
        
        // The manager hands over its latest location when sharing starts, so only later shares resend it here.
        if wasSharing, let lastLocation {
            locationUpdated(lastLocation)
        }
    }
    
    private func syncActiveRoomProxies(with sessions: [String: LiveLocationSession]) {
        // Remove proxies for rooms no longer in the dictionary.
        let activeRoomIDs = Set(sessions.keys)
        for roomID in activeRoomProxies.keys where !activeRoomIDs.contains(roomID) {
            activeRoomProxies.removeValue(forKey: roomID)
        }
    }
    
    private func scheduleExpiry(of sessions: [String: LiveLocationSession]) {
        guard let nextExpirationDate = sessions.values.map(\.expirationDate).min() else {
            expiryTask = nil
            return
        }
        
        let delay = nextExpirationDate.timeIntervalSince(timeProvider.now())
        expiryTask = Task { [weak self, clock = timeProvider.clock] in
            try? await clock.sleep(for: .seconds(delay))
            guard !Task.isCancelled, let self else { return }
            
            // The wall clock can lag behind the sleep's clock, so wait out whatever is left.
            if !stopExpiredLiveLocations() {
                scheduleExpiry(of: userSettings.account.liveLocationSharingSessionsByRoomID)
            }
        }
    }
    
    /// Returns whether any share had expired.
    @discardableResult
    private func stopExpiredLiveLocations() -> Bool {
        let now = timeProvider.now()
        let sessions = userSettings.account.liveLocationSharingSessionsByRoomID
        let expiredRoomIDs = sessions.filter { now >= $0.value.expirationDate }.map(\.key)
        guard !expiredRoomIDs.isEmpty else { return false }
        
        MXLog.info("Live location sessions expired for rooms: \(expiredRoomIDs)")
        // Forgotten straight away so sharing stops now, their stop events follow.
        userSettings.account.liveLocationSharingSessionsByRoomID = sessions.filter { now < $0.value.expirationDate }
        
        Task { [weak self] in
            for roomID in expiredRoomIDs {
                await self?.stopLiveLocation(roomID: roomID)
            }
        }
        
        return true
    }
    
    /// Kicks off a send cycle if one isn't already running. Each cycle:
    /// 1. Takes the latest pending location and clears it.
    /// 2. Sends the location to all active rooms **and** waits a minimum 3-second delay (in parallel).
    /// 3. After both complete, checks for a new pending location and loops if one exists.
    /// This ensures at least 3 seconds or the send duration itself between consecutive sends,
    /// discarding any intermediate updates while always keeping the last one.
    private func processLocationUpdateIfNeeded() {
        guard !isProcessingLocationUpdate,
              let location = latestPendingLocation,
              !userSettings.account.liveLocationSharingSessionsByRoomID.isEmpty else {
            return
        }
        
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
        let sessions = userSettings.account.liveLocationSharingSessionsByRoomID
        let geoURI = GeoURI(coordinate: coordinate, uncertainty: nil)
        
        for (roomID, session) in sessions {
            if timeProvider.now() >= session.expirationDate {
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
}

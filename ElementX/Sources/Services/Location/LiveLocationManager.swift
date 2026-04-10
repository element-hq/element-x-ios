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
    private let locationManager: CLLocationManager
    private let appSettings: AppSettings
    
    private let authorizationStatusSubject: CurrentValueSubject<CLAuthorizationStatus, Never>
    
    /// Cached joined room proxies keyed by room ID, kept in sync with the active sessions dictionary.
    private var activeRoomProxies = [String: JoinedRoomProxyProtocol]()
    
    /// The running task that iterates over live location updates.
    @CancellableTask
    private var locationUpdatesTask: Task<Void, Never>?
    
    private var cancellables = Set<AnyCancellable>()
    
    var authorizationStatus: CurrentValuePublisher<CLAuthorizationStatus, Never> {
        authorizationStatusSubject.asCurrentValuePublisher()
    }
    
    @MainActor
    init(clientProxy: ClientProxyProtocol,
         appSettings: AppSettings) {
        self.clientProxy = clientProxy
        self.appSettings = appSettings
        // Very important, the CLLocationManager needs to be initialised on the main thread
        // or the delegate functions won't be handled!
        // https://developer.apple.com/documentation/corelocation/cllocationmanagerdelegate
        locationManager = CLLocationManager()
        authorizationStatusSubject = CurrentValueSubject(locationManager.authorizationStatus)
        
        super.init()
        
        locationManager.delegate = self
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.pausesLocationUpdatesAutomatically = false
        
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
        
        authorizationStatusSubject.send(manager.authorizationStatus)
    }
    
    // MARK: - Private
    
    private func setupSubscriptions() {
        appSettings.$liveLocationSharingTimeoutDatesByRoomID
            .removeDuplicates()
            .sink { [weak self] sessions in
                guard let self else { return }
                syncActiveRoomProxies(with: sessions)
                
                if sessions.isEmpty {
                    locationUpdatesTask = nil
                } else {
                    startLocationUpdatesIfNeeded()
                }
            }
            .store(in: &cancellables)
        
        appSettings.$liveLocationSharingEnabled
            .filter { !$0 }
            .sink { [weak self] _ in
                guard let self else { return }
                appSettings.liveLocationSharingTimeoutDatesByRoomID.removeAll()
                activeRoomProxies.removeAll()
                locationUpdatesTask = nil
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
    
    private func startLocationUpdatesIfNeeded() {
        guard locationUpdatesTask == nil else { return }
        
        locationUpdatesTask = Task { [weak self] in
            do {
                for try await update in CLLocationUpdate.liveUpdates() {
                    guard let self, !Task.isCancelled else { break }
                    
                    await self.sendLocationToActiveRooms(update)
                }
            } catch {
                MXLog.error("Live location updates failed with error: \(error)")
                self?.stopAllSessions()
            }
        }
    }
    
    private func sendLocationToActiveRooms(_ update: CLLocationUpdate) async {
        let sessions = appSettings.liveLocationSharingTimeoutDatesByRoomID
        let geoURI = update.location.map { GeoURI(coordinate: $0.coordinate, uncertainty: $0.horizontalAccuracy) }
        
        for (roomID, timeoutDate) in sessions {
            if Date() >= timeoutDate {
                MXLog.info("Live location session expired for room: \(roomID)")
                await stopLiveLocation(roomID: roomID)
                continue
            }
            
            guard let geoURI else { continue }
            
            let roomProxy = await resolveRoomProxy(for: roomID)
            guard let roomProxy else {
                MXLog.error("Failed to resolve room proxy for live location update in room: \(roomID)")
                continue
            }
            
            let result = await roomProxy.sendLiveLocation(geoURI: geoURI)
            if case .failure(let error) = result {
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

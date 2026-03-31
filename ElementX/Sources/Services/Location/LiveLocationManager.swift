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
    }
    
    // MARK: - LiveLocationManagerProtocol
    
    @discardableResult
    func requestAlwaysAuthorizationIfPossible() -> Bool {
        guard !appSettings.hasRequestedAlwaysLocationAuthorization else { return false }
        appSettings.hasRequestedAlwaysLocationAuthorization = true
        locationManager.requestAlwaysAuthorization()
        return true
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        // If the system resets authorization to notDetermined (e.g. after app reinstall or
        // settings reset), clear the flag so we can request again.
        if manager.authorizationStatus == .notDetermined {
            appSettings.hasRequestedAlwaysLocationAuthorization = false
        }
        authorizationStatusSubject.send(manager.authorizationStatus)
    }
    
    // MARK: - Private
    
    // TODO: Add CLLocationManager location update handling to forward updates to rooms
    // TODO: Track which rooms are currently sharing live location
    // TODO: Send location updates to all active rooms via clientProxy
}

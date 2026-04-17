//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import CoreLocation

// sourcery: AutoMockable
protocol CLLocationManagerProtocol: AnyObject {
    var delegate: CLLocationManagerDelegate? { get set }
    var allowsBackgroundLocationUpdates: Bool { get set }
    var desiredAccuracy: CLLocationAccuracy { get set }
    var pausesLocationUpdatesAutomatically: Bool { get set }
    var authorizationStatus: CLAuthorizationStatus { get }
    
    func requestAlwaysAuthorization()
}

extension CLLocationManager: CLLocationManagerProtocol { }

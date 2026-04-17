//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import CoreLocation

extension CLLocationManagerMock {
    struct Configuration {
        var authorizationStatus: CLAuthorizationStatus = .authorizedAlways
    }
    
    convenience init(_ configuration: Configuration) {
        self.init()
        
        underlyingAuthorizationStatus = configuration.authorizationStatus
    }
}

//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import CoreLocation

extension LiveLocationServiceMock {
    struct Configuration {
        var userID = "@alice:matrix.org"
        var authorizationStatus: CLAuthorizationStatus = .notDetermined
        var requestAlwaysAuthorizationIfPossibleReturnValue = true
        var isSharing = false
    }
    
    convenience init(_ configuration: Configuration) {
        self.init()
        
        userID = configuration.userID
        actionsPublisher = PassthroughSubject<LiveLocationServiceAction, Never>().eraseToAnyPublisher()
        isSharingPublisher = CurrentValueSubject(configuration.isSharing).asCurrentValuePublisher()
        
        let authorizationStatusSubject = CurrentValueSubject<CLAuthorizationStatus, Never>(configuration.authorizationStatus)
        authorizationStatus = .init(authorizationStatusSubject)
        
        requestAlwaysAuthorizationIfPossibleReturnValue = configuration.requestAlwaysAuthorizationIfPossibleReturnValue
        startLiveLocationRoomIDDurationReturnValue = .success(())
    }
}

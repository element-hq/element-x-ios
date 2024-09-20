//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation
import MatrixRustSDK

extension ClientSDKMock {
    struct Configuration {
        // MARK: Authentication
        
        var serverAddress = "matrix.org"
        var homeserverURL = "https://matrix-client.matrix.org"
        var slidingSyncVersion = SlidingSyncVersion.native
        var supportsPasswordLogin = true
        var supportsOIDCLogin = false
        var elementWellKnown = "{\"registration_helper_url\":\"https://develop.element.io/#/mobile_register\"}"
        
        // MARK: Session
        
        var userID: String?
        var session = Session(accessToken: UUID().uuidString,
                              refreshToken: nil,
                              userId: "@alice:matrix.org",
                              deviceId: UUID().uuidString,
                              homeserverUrl: "https://matrix-client.matrix.org",
                              oidcData: nil,
                              slidingSyncVersion: .native)
    }
    
    enum MockError: Error { case generic }
    
    convenience init(configuration: Configuration) {
        self.init()
        
        homeserverLoginDetailsReturnValue = HomeserverLoginDetailsSDKMock(configuration: configuration)
        slidingSyncVersionReturnValue = configuration.slidingSyncVersion
        userIdServerNameThrowableError = MockError.generic
        serverReturnValue = "https://\(configuration.serverAddress)"
        getUrlUrlReturnValue = configuration.elementWellKnown
        
        userIdReturnValue = configuration.userID
        sessionReturnValue = configuration.session
    }
}

extension HomeserverLoginDetailsSDKMock {
    convenience init(configuration: ClientSDKMock.Configuration) {
        self.init()
        
        slidingSyncVersionReturnValue = configuration.slidingSyncVersion
        supportsPasswordLoginReturnValue = configuration.supportsPasswordLogin
        supportsOidcLoginReturnValue = configuration.supportsOIDCLogin
        urlReturnValue = configuration.homeserverURL
    }
}

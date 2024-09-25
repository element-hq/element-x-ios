//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation
import MatrixRustSDK

extension AuthenticationClientBuilderMock {
    struct Configuration {
        var homeserverClients = [
            "matrix.org": ClientSDKMock(configuration: .init()),
            "example.com": ClientSDKMock(configuration: .init(serverAddress: "example.com",
                                                              homeserverURL: "https://matrix.example.com",
                                                              slidingSyncVersion: .native,
                                                              supportsPasswordLogin: true,
                                                              elementWellKnown: "")),
            "company.com": ClientSDKMock(configuration: .init(serverAddress: "company.com",
                                                              homeserverURL: "https://matrix.company.com",
                                                              slidingSyncVersion: .native,
                                                              oidcLoginURL: "https://auth.company.com/oidc",
                                                              supportsPasswordLogin: false,
                                                              elementWellKnown: "")),
            "server.net": ClientSDKMock(configuration: .init(serverAddress: "server.net",
                                                             homeserverURL: "https://matrix.example.com",
                                                             slidingSyncVersion: .native,
                                                             supportsPasswordLogin: false,
                                                             elementWellKnown: ""))
        ]
        var qrCodeClient = ClientSDKMock(configuration: .init())
    }
    
    convenience init(configuration: Configuration) {
        self.init()
        
        buildHomeserverAddressClosure = { address in
            guard let client = configuration.homeserverClients[address] else {
                throw ClientBuildError.ServerUnreachable(message: "Not a known homeserver.")
            }
            return client
        }
        
        buildWithQRCodeQrCodeDataOidcConfigurationProgressListenerReturnValue = configuration.qrCodeClient
    }
}

//
// Copyright 2025 Element Creations Ltd.
// Copyright 2024-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRustSDK
import MatrixRustSDKMocks

extension ClientFactoryMock {
    struct Configuration {
        var homeserverClients = [
            "matrix.org": ClientSDKMock(.init()),
            "https://matrix-client.matrix.org": ClientSDKMock(.init()),
            "example.com": ClientSDKMock(.init(serverName: "example.com",
                                               homeserverURL: "https://matrix.example.com",
                                               slidingSyncVersion: .native,
                                               oAuthLoginURL: nil,
                                               supportsOAuthCreatePrompt: false,
                                               supportsPasswordLogin: true)),
            "company.com": ClientSDKMock(.init(serverName: "company.com",
                                               homeserverURL: "https://matrix.company.com",
                                               slidingSyncVersion: .native,
                                               oAuthLoginURL: "https://auth.company.com/login",
                                               supportsOAuthCreatePrompt: false,
                                               supportsPasswordLogin: false)),
            "server.net": ClientSDKMock(.init(serverName: "server.net",
                                              homeserverURL: "https://matrix.server.net",
                                              slidingSyncVersion: .native,
                                              oAuthLoginURL: nil,
                                              supportsOAuthCreatePrompt: false,
                                              supportsPasswordLogin: false)),
            "secure.gov": ClientSDKMock(.init(serverName: "secure.gov",
                                              homeserverURL: "https://ess.secure.gov",
                                              slidingSyncVersion: .native,
                                              oAuthLoginURL: "https://auth.secure.gov/login",
                                              supportsOAuthCreatePrompt: false,
                                              supportsPasswordLogin: false,
                                              elementWellKnown: "{\"version\":1,\"enforce_element_pro\":true}"))
        ]
    }
    
    convenience init(_ configuration: Configuration) {
        self.init()
        
        makeAuthenticationClientServerNameOrBaseURLSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksClosure = { address, _, _, _, _, _ in
            guard let client = configuration.homeserverClients[address] else {
                throw ClientBuildError.ServerUnreachable(message: "Not a known homeserver.")
            }
            return client
        }
        
        makeInMemoryClientServerNameOrBaseURLClientSessionDelegateAppSettingsAppHooksClosure = { address, _, _, _ in
            guard let client = configuration.homeserverClients[address] else {
                throw ClientBuildError.ServerUnreachable(message: "Not a known homeserver.")
            }
            return client
        }
        
        makeAppClientCredentialsClientSessionDelegateAppSettingsAppHooksClosure = { credentials, _, _, _ in
            ClientSDKMock(.init(userID: credentials.userID))
        }
        
        makeNSEClientCredentialsRoomIDClientSessionDelegateAppSettingsAppHooksClosure = { credentials, _, _, _, _ in
            ClientSDKMock(.init(userID: credentials.userID))
        }
    }
}

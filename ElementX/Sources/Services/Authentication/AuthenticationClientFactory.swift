//
// Copyright 2025 Element Creations Ltd.
// Copyright 2024-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRustSDK

// sourcery: AutoMockable
protocol AuthenticationClientFactoryProtocol {
    func makeClient(homeserverAddress: String,
                    sessionDirectories: SessionDirectories,
                    passphrase: String,
                    clientSessionDelegate: ClientSessionDelegate,
                    appSettings: AppSettings,
                    appHooks: AppHooks) async throws -> ClientProtocol
}

/// A wrapper around `ClientBuilder` to allow for mocked clients to be injected into authentication tests.
struct AuthenticationClientFactory: AuthenticationClientFactoryProtocol {
    func makeClient(homeserverAddress: String,
                    sessionDirectories: SessionDirectories,
                    passphrase: String,
                    clientSessionDelegate: ClientSessionDelegate,
                    appSettings: AppSettings,
                    appHooks: AppHooks) async throws -> ClientProtocol {
        try await ClientBuilder
            .baseBuilder(httpProxy: appSettings.websiteURL.globalProxy,
                         slidingSync: .discover,
                         sessionDelegate: clientSessionDelegate,
                         appHooks: appHooks,
                         enableOnlySignedDeviceIsolationMode: appSettings.enableOnlySignedDeviceIsolationMode,
                         enableKeyShareOnInvite: appSettings.enableKeyShareOnInvite,
                         threadsEnabled: appSettings.threadsEnabled)
            .sqliteStore(config: .init(dataPath: sessionDirectories.dataPath, cachePath: sessionDirectories.cachePath)
                .passphrase(passphrase: passphrase))
            .serverNameOrHomeserverUrl(serverNameOrUrl: homeserverAddress)
            .build()
    }
}

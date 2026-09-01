//
// Copyright 2025 Element Creations Ltd.
// Copyright 2024-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRustSDK

/// A wrapper around `ClientBuilder` to allow for mocked clients to be injected into tests.
nonisolated struct ClientFactory: ClientFactoryProtocol {
    // MARK: Authentication
    
    #if IS_MAIN_APP
    func makeAuthenticationClient(homeserverAddress: String,
                                  sessionDirectories: SessionDirectories,
                                  passphrase: String,
                                  clientSessionDelegate: ClientSessionDelegate,
                                  appSettings: AppSettings,
                                  appHooks: AppHooks) async throws -> ClientProtocol {
        let builder = makeBaseBuilder(httpProxy: appSettings.websiteURL.globalProxy,
                                      discoverSlidingSync: true,
                                      sessionDelegate: clientSessionDelegate,
                                      appHooks: appHooks,
                                      enableOnlySignedDeviceIsolationMode: appSettings.enableOnlySignedDeviceIsolationMode,
                                      threadsEnabled: appSettings.threadsEnabled)
            .enableAutomaticBackPagination(enableAutomaticBackPagination: appSettings.automaticBackPaginationEnabled)
            .sqliteStore(config: .init(dataPath: sessionDirectories.dataPath, cachePath: sessionDirectories.cachePath)
                .passphrase(passphrase: passphrase))
            .serverNameOrHomeserverUrl(serverNameOrUrl: homeserverAddress)
        
        return try await build(builder, for: .authentication, appHooks: appHooks)
    }
    
    func makeInMemoryClient(homeserverAddress: String,
                            clientSessionDelegate: ClientSessionDelegate,
                            appSettings: AppSettings,
                            appHooks: AppHooks) async throws -> ClientProtocol {
        let builder = makeBaseBuilder(httpProxy: appSettings.websiteURL.globalProxy,
                                      discoverSlidingSync: true,
                                      sessionDelegate: clientSessionDelegate,
                                      appHooks: appHooks,
                                      enableOnlySignedDeviceIsolationMode: appSettings.enableOnlySignedDeviceIsolationMode,
                                      threadsEnabled: appSettings.threadsEnabled)
            .inMemoryStore()
            .serverNameOrHomeserverUrl(serverNameOrUrl: homeserverAddress)
        
        return try await build(builder, for: .classicAppAccount, appHooks: appHooks)
    }
    
    // MARK: Restoration
    
    func makeAppClient(credentials: KeychainCredentials,
                       clientSessionDelegate: ClientSessionDelegate,
                       appSettings: AppSettings,
                       appHooks: AppHooks) async throws -> ClientProtocol {
        let homeserverURL = credentials.restorationToken.session.homeserverUrl
        
        let builder = makeBaseBuilder(httpProxy: URL(string: homeserverURL)?.globalProxy,
                                      discoverSlidingSync: false,
                                      sessionDelegate: clientSessionDelegate,
                                      appHooks: appHooks,
                                      enableOnlySignedDeviceIsolationMode: appSettings.enableOnlySignedDeviceIsolationMode,
                                      threadsEnabled: appSettings.threadsEnabled)
            .enableAutomaticBackPagination(enableAutomaticBackPagination: appSettings.automaticBackPaginationEnabled)
            .sqliteStore(config: .init(dataPath: credentials.restorationToken.sessionDirectories.dataPath,
                                       cachePath: credentials.restorationToken.sessionDirectories.cachePath)
                    .passphrase(passphrase: credentials.restorationToken.passphrase))
            .withSearchIndexStore(path: credentials.restorationToken.sessionDirectories.dataPath,
                                  password: credentials.restorationToken.passphrase)
            .homeserverUrl(url: homeserverURL)
        
        return try await build(builder, for: .restoration(credentials.restorationToken.session, .all), appHooks: appHooks)
    }
    #endif
    
    func makeNSEClient(credentials: KeychainCredentials,
                       roomID: String,
                       clientSessionDelegate: ClientSessionDelegate,
                       appSettings: CommonSettingsProtocol,
                       appHooks: AppHooks) async throws -> ClientProtocol {
        let homeserverURL = credentials.restorationToken.session.homeserverUrl
        
        let builder = makeBaseBuilder(setupEncryption: false,
                                      httpProxy: URL(string: homeserverURL)?.globalProxy,
                                      discoverSlidingSync: false,
                                      sessionDelegate: clientSessionDelegate,
                                      appHooks: appHooks,
                                      enableOnlySignedDeviceIsolationMode: appSettings.enableOnlySignedDeviceIsolationMode,
                                      requestTimeout: 15000,
                                      maxRequestRetryTime: 5000,
                                      threadsEnabled: appSettings.threadsEnabled)
            .systemIsMemoryConstrained()
            .sqliteStore(config: .init(dataPath: credentials.restorationToken.sessionDirectories.dataPath,
                                       cachePath: credentials.restorationToken.sessionDirectories.cachePath)
                    .passphrase(passphrase: credentials.restorationToken.passphrase))
            .homeserverUrl(url: homeserverURL)
        
        return try await build(builder, for: .restoration(credentials.restorationToken.session, .one(roomId: roomID)), appHooks: appHooks)
    }
    
    // MARK: - Helpers
    
    /// A helper method that applies the common builder modifiers needed for the app.
    private func makeBaseBuilder(setupEncryption: Bool = true,
                                 httpProxy: String? = nil,
                                 discoverSlidingSync: Bool,
                                 sessionDelegate: ClientSessionDelegate,
                                 appHooks: AppHooks,
                                 enableOnlySignedDeviceIsolationMode: Bool,
                                 requestTimeout: UInt64? = 30000,
                                 maxRequestRetryTime: UInt64? = nil,
                                 threadsEnabled: Bool) -> ClientBuilder {
        var builder = ClientBuilder()
            .crossProcessLockConfig(crossProcessLockConfig: .multiProcess(holderName: InfoPlistReader.main.bundleIdentifier))
            .setSessionDelegate(sessionDelegate: sessionDelegate)
            .userAgent(userAgent: UserAgentBuilder.makeASCIIUserAgent())
            .threadsEnabled(enabled: threadsEnabled, threadSubscriptions: threadsEnabled)
            .requestConfig(config: .init(retryLimit: 3, // Must be non-zero for the SDK to retry API calls when rate-limited.
                                         timeout: requestTimeout,
                                         maxConcurrentRequests: nil,
                                         maxRetryTime: maxRequestRetryTime))
            .dmRoomDefinition(dmRoomDefinition: .twoMembers)
        
        if discoverSlidingSync {
            builder = builder.slidingSyncVersionBuilder(versionBuilder: .discoverNative)
        }
        
        if setupEncryption {
            builder = builder
                .autoEnableCrossSigning(autoEnableCrossSigning: true)
                .backupDownloadStrategy(backupDownloadStrategy: .afterDecryptionFailure)
                .enableShareHistoryOnInvite(enableShareHistoryOnInvite: true)
                .autoEnableBackups(autoEnableBackups: true)
        }
        
        // Set recipient strategy and trust requirement even if `setupEncryption` is false to ensure messages
        // from insecure devices aren't displayed in push notifications.
        // See https://github.com/element-hq/element-x-ios/issues/4702.
        if enableOnlySignedDeviceIsolationMode {
            builder = builder
                .roomKeyRecipientStrategy(strategy: .identityBasedStrategy)
                .decryptionSettings(decryptionSettings: .init(senderDeviceTrustRequirement: .crossSignedOrLegacy))
        } else {
            builder = builder
                .roomKeyRecipientStrategy(strategy: .errorOnVerifiedUserProblem)
                .decryptionSettings(decryptionSettings: .init(senderDeviceTrustRequirement: .untrusted))
        }
        
        if let httpProxy {
            builder = builder.proxy(url: httpProxy)
        }
        
        return builder
    }
    
    private func build(_ builder: ClientBuilder,
                       for mode: BuildMode,
                       appHooks: AppHooks) async throws -> ClientProtocol {
        var client: ClientProtocol = try await appHooks.clientFactoryHook.configure(builder, toRestore: mode.session).build()
        
        switch mode {
        case .authentication:
            break
        case .restoration(let session, let roomLoadSettings):
            try await client.restoreSessionWith(session: session, roomLoadSettings: roomLoadSettings)
        case .classicAppAccount:
            break
        }
        
        return client
    }
    
    private enum BuildMode {
        case authentication
        case restoration(Session, RoomLoadSettings)
        case classicAppAccount
        
        var session: Session? {
            switch self {
            case .authentication, .classicAppAccount: nil
            case .restoration(let session, _): session
            }
        }
    }
}

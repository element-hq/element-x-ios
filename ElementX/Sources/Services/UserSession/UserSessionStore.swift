//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRustSDK

class UserSessionStore: UserSessionStoreProtocol {
    private let keychainController: KeychainControllerProtocol
    private let appSettings: AppSettings
    private let networkMonitor: NetworkMonitorProtocol
    private let appHooks: AppHooks
    
    /// Whether or not there are sessions in the store.
    var hasSessions: Bool { !keychainController.restorationTokens().isEmpty }
    /// All the user IDs managed by the store.
    var userIDs: [String] { keychainController.restorationTokens().map(\.userID) }
    
    var clientSessionDelegate: ClientSessionDelegate { keychainController }
    
    init(keychainController: KeychainControllerProtocol,
         appSettings: AppSettings,
         appHooks: AppHooks,
         networkMonitor: NetworkMonitorProtocol) {
        self.keychainController = keychainController
        self.appSettings = appSettings
        self.appHooks = appHooks
        self.networkMonitor = networkMonitor
    }
    
    /// Deletes all data stored in the shared container and keychain
    func reset() {
        MXLog.warning("Resetting the UserSessionStore. All accounts will be affected.")
        try? FileManager.default.removeItem(at: .sessionsBaseDirectory)
        keychainController.removeAllRestorationTokens()
    }
    
    func restoreUserSession() async -> Result<UserSessionProtocol, UserSessionStoreError> {
        let availableCredentials = keychainController.restorationTokens()
        
        guard let credentials = availableCredentials.first else {
            return .failure(.missingCredentials)
        }
        
        switch await restorePreviousLogin(credentials) {
        case .success(let clientProxy):
            return .success(buildUserSessionWithClient(clientProxy))
        case .failure(let error):
            MXLog.error("Failed restoring login with error: \(error)")
            
            // On any restoration failure reset the token and restart
            keychainController.removeRestorationTokenForUsername(credentials.userID)
            credentials.restorationToken.sessionDirectories.delete()
            
            return .failure(error)
        }
    }
    
    func userSession(for client: ClientProtocol, sessionDirectories: SessionDirectories, passphrase: String) async -> Result<UserSessionProtocol, UserSessionStoreError> {
        do {
            let session = try client.session()
            let userID = try client.userId()
            let clientProxy = try await setupProxyForClient(client)
            
            keychainController.setRestorationToken(RestorationToken(session: session,
                                                                    sessionDirectories: sessionDirectories,
                                                                    passphrase: passphrase,
                                                                    pusherNotificationClientIdentifier: clientProxy.pusherNotificationClientIdentifier),
                                                   forUsername: userID)
            
            MXLog.info("Set up session for user \(userID) at: \(sessionDirectories)")
            
            return .success(buildUserSessionWithClient(clientProxy))
        } catch {
            MXLog.error("Failed creating user session with error: \(error)")
            return .failure(.failedSettingUpSession)
        }
    }
    
    func logout(userSession: UserSessionProtocol) {
        let userID = userSession.clientProxy.userID
        let credentials = keychainController.restorationTokens().first { $0.userID == userID }
        keychainController.removeRestorationTokenForUsername(userID)
        
        if let credentials {
            credentials.restorationToken.sessionDirectories.delete()
        }
    }
        
    // MARK: - Private
    
    private func buildUserSessionWithClient(_ clientProxy: ClientProxyProtocol) -> UserSessionProtocol {
        let mediaProvider = MediaProvider(mediaLoader: clientProxy.mediaLoader,
                                          imageCache: .onlyInMemory,
                                          homeserverReachabilityPublisher: clientProxy.homeserverReachabilityPublisher)
        
        let voiceMessageMediaManager = VoiceMessageMediaManager(mediaProvider: mediaProvider)
        
        return UserSession(clientProxy: clientProxy,
                           mediaProvider: mediaProvider,
                           voiceMessageMediaManager: voiceMessageMediaManager)
    }
    
    private func restorePreviousLogin(_ credentials: KeychainCredentials) async -> Result<ClientProxyProtocol, UserSessionStoreError> {
        guard credentials.restorationToken.sessionDirectories.isNonTransientUserDataValid() else {
            MXLog.error("Failed restoring login, missing non-transient user data")
            return .failure(.failedRestoringLogin)
        }
        
        let homeserverURL = credentials.restorationToken.session.homeserverUrl
        await appHooks.remoteSettingsHook.loadCache(forHomeserver: homeserverURL, applyingTo: appSettings)
        
        let builder = ClientBuilder
            .baseBuilder(httpProxy: URL(string: homeserverURL)?.globalProxy,
                         slidingSync: .restored,
                         sessionDelegate: keychainController,
                         appHooks: appHooks,
                         enableOnlySignedDeviceIsolationMode: appSettings.enableOnlySignedDeviceIsolationMode,
                         enableKeyShareOnInvite: appSettings.enableKeyShareOnInvite,
                         threadsEnabled: appSettings.threadsEnabled)
            .sqliteStore(config: .init(dataPath: credentials.restorationToken.sessionDirectories.dataPath,
                                       cachePath: credentials.restorationToken.sessionDirectories.cachePath)
                    .passphrase(passphrase: credentials.restorationToken.passphrase))
            .username(username: credentials.userID)
            .homeserverUrl(url: homeserverURL)
        
        do {
            let client = try await builder.build()
            try await client.restoreSession(session: credentials.restorationToken.session)
            
            MXLog.info("Set up session for user \(credentials.userID) at: \(credentials.restorationToken.sessionDirectories)")
            
            Task(priority: .low) { await appHooks.remoteSettingsHook.updateCache(using: client) }
            
            return try await .success(setupProxyForClient(client))
        } catch UserSessionStoreError.failedSettingUpClientProxy(let error) {
            // If this has failed, there is likely something wrong with the creation of the sync service
            // There is nothing we can do, but at the same time we don't want the user to the get logged out
            // So it's better to crash here and let the app restart
            fatalError("Failed setting up the client proxy with error: \(error)")
        } catch {
            MXLog.error("Failed restoring login with error: \(error)")
            return .failure(.failedRestoringLogin)
        }
    }
    
    private func setupProxyForClient(_ client: ClientProtocol) async throws -> ClientProxyProtocol {
        do {
            return try await ClientProxy(client: client,
                                         networkMonitor: networkMonitor,
                                         appSettings: appSettings)
        } catch {
            throw UserSessionStoreError.failedSettingUpClientProxy(error)
        }
    }
}

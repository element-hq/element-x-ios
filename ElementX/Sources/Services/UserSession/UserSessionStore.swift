//
// Copyright 2022 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation
import Kingfisher
import MatrixRustSDK

class UserSessionStore: UserSessionStoreProtocol {
    private let keychainController: KeychainControllerProtocol
    private let matrixSDKStateKey = "matrix-sdk-state"
    
    /// Whether or not there are sessions in the store.
    var hasSessions: Bool { !keychainController.restorationTokens().isEmpty }
    /// All the user IDs managed by the store.
    var userIDs: [String] { keychainController.restorationTokens().map(\.userID) }
    
    var clientSessionDelegate: ClientSessionDelegate { keychainController }
    
    init(keychainController: KeychainControllerProtocol) {
        self.keychainController = keychainController
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
            deleteSessionDirectory(for: credentials)
            
            return .failure(error)
        }
    }
    
    func userSession(for client: Client, sessionDirectory: URL, passphrase: String?) async -> Result<UserSessionProtocol, UserSessionStoreError> {
        do {
            let session = try client.session()
            let userID = try client.userId()
            let clientProxy = await setupProxyForClient(client)
            
            keychainController.setRestorationToken(RestorationToken(session: session,
                                                                    sessionDirectory: sessionDirectory,
                                                                    passphrase: passphrase,
                                                                    pusherNotificationClientIdentifier: clientProxy.pusherNotificationClientIdentifier),
                                                   forUsername: userID)
            
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
            deleteSessionDirectory(for: credentials)
        }
    }
    
    func clearCache(for userID: String) {
        guard let credentials = keychainController.restorationTokens().first(where: { $0.userID == userID }) else {
            MXLog.error("Failed to clearing caches: Credentials missing")
            return
        }
        deleteCaches(for: credentials)
    }
    
    // MARK: - Private
    
    private func buildUserSessionWithClient(_ clientProxy: ClientProxyProtocol) -> UserSessionProtocol {
        let mediaProvider = MediaProvider(mediaLoader: clientProxy,
                                          imageCache: .onlyInMemory)
        
        let voiceMessageMediaManager = VoiceMessageMediaManager(mediaProvider: mediaProvider)
        
        return UserSession(clientProxy: clientProxy,
                           mediaProvider: mediaProvider,
                           voiceMessageMediaManager: voiceMessageMediaManager)
    }
    
    private func restorePreviousLogin(_ credentials: KeychainCredentials) async -> Result<ClientProxyProtocol, UserSessionStoreError> {
        if credentials.restorationToken.passphrase != nil {
            MXLog.info("Restoring client with encrypted store.")
        }
        
        let homeserverURL = credentials.restorationToken.session.homeserverUrl
        
        var builder = ClientBuilder()
            .sessionPath(path: credentials.restorationToken.sessionDirectory.path(percentEncoded: false))
            .username(username: credentials.userID)
            .homeserverUrl(url: homeserverURL)
            .passphrase(passphrase: credentials.restorationToken.passphrase)
            .userAgent(userAgent: UserAgentBuilder.makeASCIIUserAgent())
            .enableCrossProcessRefreshLock(processId: InfoPlistReader.main.bundleIdentifier,
                                           sessionDelegate: keychainController)
            .serverVersions(versions: ["v1.0", "v1.1", "v1.2", "v1.3", "v1.4", "v1.5"]) // FIXME: Quick and dirty fix for stopping version requests on startup https://github.com/matrix-org/matrix-rust-sdk/pull/1376
        
        if let homeserverURL = URL(string: homeserverURL),
           let proxy = homeserverURL.globalProxy {
            builder = builder.proxy(url: proxy)
        }
        let completeBuilder = builder
        
        do {
            let client = try await completeBuilder.build()
            
            try await client.restoreSession(session: credentials.restorationToken.session)
            
            return await .success(setupProxyForClient(client))
        } catch {
            MXLog.error("Failed restoring login with error: \(error)")
            return .failure(.failedRestoringLogin)
        }
    }
    
    private func setupProxyForClient(_ client: Client) async -> ClientProxyProtocol {
        await ClientProxy(client: client,
                          networkMonitor: ServiceLocator.shared.networkMonitor)
    }
    
    private func deleteSessionDirectory(for credentials: KeychainCredentials) {
        do {
            try FileManager.default.removeItem(at: credentials.restorationToken.sessionDirectory)
        } catch {
            MXLog.failure("Failed deleting the session data: \(error)")
        }
    }
    
    private func deleteCaches(for credentials: KeychainCredentials) {
        do {
            let sessionDirectoryContents = try FileManager.default.contentsOfDirectory(at: credentials.restorationToken.sessionDirectory, includingPropertiesForKeys: nil)
            for url in sessionDirectoryContents where url.path.contains(matrixSDKStateKey) {
                try FileManager.default.removeItem(at: url)
            }
        } catch {
            MXLog.failure("Failed clearing caches: \(error)")
        }
    }
}

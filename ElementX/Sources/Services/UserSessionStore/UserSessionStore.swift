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
    private let backgroundTaskService: BackgroundTaskServiceProtocol
    
    /// Whether or not there are sessions in the store.
    var hasSessions: Bool { !keychainController.restoreTokens().isEmpty }
    
    /// The base directory where all session data is stored.
    var baseDirectoryPath: String { baseDirectory().path }
    
    init(bundleIdentifier: String, backgroundTaskService: BackgroundTaskServiceProtocol) {
        keychainController = KeychainController(identifier: bundleIdentifier)
        self.backgroundTaskService = backgroundTaskService
    }
    
    func restoreUserSession() async -> Result<UserSession, UserSessionStoreError> {
        let availableCredentials = keychainController.restoreTokens()
        
        guard let credentials = availableCredentials.first else {
            return .failure(.missingCredentials)
        }
        
        switch await restorePreviousLogin(credentials) {
        case .success(let clientProxy):
            return .success(UserSession(clientProxy: clientProxy,
                                        mediaProvider: MediaProvider(clientProxy: clientProxy,
                                                                     imageCache: ImageCache.default,
                                                                     backgroundTaskService: backgroundTaskService)))
        case .failure(let error):
            MXLog.error("Failed restoring login with error: \(error)")
            
            // On any restoration failure reset the token and restart
            keychainController.removeAllRestoreTokens()
            deleteSessionDirectory(for: credentials.userID)
            
            return .failure(error)
        }
    }
    
    func userSession(for client: Client) async -> Result<UserSession, UserSessionStoreError> {
        switch await setupProxyForClient(client) {
        case .success(let clientProxy):
            return .success(UserSession(clientProxy: clientProxy,
                                        mediaProvider: MediaProvider(clientProxy: clientProxy,
                                                                     imageCache: ImageCache.default,
                                                                     backgroundTaskService: backgroundTaskService)))
        case .failure(let error):
            MXLog.error("Failed creating user session with error: \(error)")
            return .failure(error)
        }
    }
    
    func logout(userSession: UserSessionProtocol) {
        let userID = userSession.clientProxy.userIdentifier
        keychainController.removeRestoreTokenForUsername(userID)
        deleteSessionDirectory(for: userID)
    }
    
    private func restorePreviousLogin(_ credentials: KeychainCredentials) async -> Result<ClientProxyProtocol, UserSessionStoreError> {
        Benchmark.startTrackingForIdentifier("Login", message: "Started restoring previous login")
        
        let builder = ClientBuilder()
            .basePath(path: baseDirectoryPath)
            .username(username: credentials.userID)
        
        let loginTask: Task<Client, Error> = Task.detached {
            let client = try builder.build()
            try client.restoreLogin(restoreToken: credentials.restoreToken)
            return client
        }
        
        switch await loginTask.result {
        case .success(let client):
            return await setupProxyForClient(client)
        case .failure(let error):
            MXLog.error("Failed restoring login with error: \(error)")
            return .failure(.failedRestoringLogin)
        }
    }
    
    private func setupProxyForClient(_ client: Client) async -> Result<ClientProxyProtocol, UserSessionStoreError> {
        do {
            let accessToken = try client.restoreToken()
            let userId = try client.userId()
            
            keychainController.setRestoreToken(accessToken, forUsername: userId)
        } catch {
            MXLog.error("Failed setting up user session with error: \(error)")
            return .failure(.failedSettingUpSession)
        }
        
        let clientProxy = ClientProxy(client: client, backgroundTaskService: backgroundTaskService)
        
        return .success(clientProxy)
    }
    
    private func deleteSessionDirectory(for userID: String) {
        // Rust sanitises the user ID replacing invalid characters with an _
        let sanitisedUserID = userID.replacingOccurrences(of: ":", with: "_")
        let url = baseDirectory().appendingPathComponent(sanitisedUserID)
        
        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            MXLog.failure("Failed deleting the session data: \(error)")
        }
    }
    
    func baseDirectory() -> URL {
        guard let appGroupContainerURL = FileManager.default.appGroupContainerURL else {
            fatalError("Should always be able to retrieve the container directory")
        }
        
        let url = appGroupContainerURL
            .appendingPathComponent("Library", isDirectory: true)
            .appendingPathComponent("Caches", isDirectory: true)
            .appendingPathComponent("Sessions", isDirectory: true)
        
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: false, attributes: nil)
        
        return url
    }
}

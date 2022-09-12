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

import AppAuth
import Foundation
import MatrixRustSDK

class AuthenticationServiceProxy: AuthenticationServiceProxyProtocol {
    // MARK: - Properties
    
    // MARK: Private
    
    private let authenticationService: AuthenticationService
    private let userSessionStore: UserSessionStoreProtocol
    
    // MARK: Public
    
    private(set) var homeserver = LoginHomeserver(address: BuildSettings.defaultHomeserverAddress, loginMode: .unknown)
    
    // MARK: - Setup
    
    init(userSessionStore: UserSessionStoreProtocol) {
        self.userSessionStore = userSessionStore
        authenticationService = AuthenticationService(basePath: userSessionStore.baseDirectoryPath)
    }
    
    // MARK: - Public
    
    func configure(for homeserverAddress: String) async -> Result<Void, AuthenticationServiceError> {
        let task = Task.detached { () -> LoginHomeserver in
            var homeserver = LoginHomeserver(address: homeserverAddress, loginMode: .unknown)
            
            try self.authenticationService.configureHomeserver(serverName: homeserverAddress)
            
            guard let details = self.authenticationService.homeserverDetails() else { return homeserver }
            
            if let issuer = details.authenticationIssuer(), let issuerURL = URL(string: issuer) {
                homeserver.loginMode = .oidc(issuerURL)
            } else if details.supportsPasswordLogin() {
                homeserver.loginMode = .password
            } else {
                homeserver.loginMode = .unsupported
            }
            
            return homeserver
        }
        
        switch await task.result {
        case .success(let homeserver):
            self.homeserver = homeserver
            return .success(())
        case .failure(let error):
            MXLog.error("Failed configuring a server: \(error)")
            return .failure(.invalidHomeserverAddress)
        }
    }
    
    func loginWithOIDC(userAgent: OIDExternalUserAgentIOS) async -> Result<UserSessionProtocol, AuthenticationServiceError> {
        guard case let .oidc(issuerURL) = homeserver.loginMode else {
            return .failure(.oidcError(.notSupported))
        }
        
        let token: String
        let deviceID = generateDeviceID()
        do {
            let oidcService = OIDCService(issuerURL: issuerURL)
            let configuration = try await oidcService.metadata()
            let registationResponse = try await oidcService.registerClient(metadata: configuration)
            let authResponse = try await oidcService.presentWebAuthentication(metadata: configuration,
                                                                              clientID: registationResponse.clientID,
                                                                              scope: "openid urn:matrix:org.matrix.msc2967.client:api:* urn:matrix:org.matrix.msc2967.client:device:\(deviceID)",
                                                                              userAgent: userAgent)
            let tokenResponse = try await oidcService.redeemCodeForTokens(authResponse: authResponse)
            
            guard let accessToken = tokenResponse.accessToken else { return .failure(.oidcError(.unknown)) }
            token = accessToken
        } catch let error as OIDCError {
            MXLog.error("Login with OIDC failed: \(error)")
            return .failure(.oidcError(error))
        } catch {
            MXLog.error("Login with OIDC failed: \(error)")
            return .failure(.failedLoggingIn)
        }
        
        do {
            let client = try authenticationService.restoreWithAccessToken(token: token, deviceId: deviceID)
            return await userSession(for: client)
        } catch {
            MXLog.debug(error)
            return .failure(.failedLoggingIn)
        }
    }
    
    func login(username: String, password: String, initialDeviceName: String, deviceId: String?) async -> Result<UserSessionProtocol, AuthenticationServiceError> {
        Benchmark.startTrackingForIdentifier("Login", message: "Started new login")
        
        let loginTask: Task<Client, Error> = Task.detached {
            try self.authenticationService.login(username: username,
                                                 password: password,
                                                 initialDeviceName: initialDeviceName,
                                                 deviceId: deviceId)
        }
        
        switch await loginTask.result {
        case .success(let client):
            Benchmark.endTrackingForIdentifier("Login", message: "Finished login")
            return await userSession(for: client)
        case .failure(let error):
            Benchmark.endTrackingForIdentifier("Login", message: "Login failed")
            
            MXLog.error("Failed logging in with error: \(error)")
            guard let error = error as? AuthenticationError else { return .failure(.failedLoggingIn) }
            
            switch error.code {
            case .forbidden:
                return .failure(.invalidCredentials)
            case .userDeactivated:
                return .failure(.accountDeactivated)
            default:
                return .failure(.failedLoggingIn)
            }
        }
    }
    
    // MARK: - Private
    
    private func userSession(for client: Client) async -> Result<UserSessionProtocol, AuthenticationServiceError> {
        switch await userSessionStore.userSession(for: client) {
        case .success(let clientProxy):
            return .success(clientProxy)
        case .failure:
            return .failure(.failedLoggingIn)
        }
    }
    
    private func generateDeviceID() -> String {
        var deviceID = ""
        for _ in 0..<10 {
            guard let scalar = UnicodeScalar(Int.random(in: 65...90)) else { fatalError() }
            deviceID.append(Character(scalar))
        }
        return deviceID
    }
}

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

import Combine
import Foundation
import MatrixRustSDK

class AuthenticationServiceProxy: AuthenticationServiceProxyProtocol {
    private let authenticationService: AuthenticationService
    private let userSessionStore: UserSessionStoreProtocol
    private let passphrase: String?
    
    private let homeserverSubject: CurrentValueSubject<LoginHomeserver, Never>
    var homeserver: CurrentValuePublisher<LoginHomeserver, Never> { homeserverSubject.asCurrentValuePublisher() }
    
    init(userSessionStore: UserSessionStoreProtocol, encryptionKeyProvider: EncryptionKeyProviderProtocol, appSettings: AppSettings) {
        let passphrase = appSettings.isDevelopmentBuild ? encryptionKeyProvider.generateKey().base64EncodedString() : nil
        if passphrase != nil {
            MXLog.info("Testing database encryption in development build.")
        }
        
        self.passphrase = passphrase
        self.userSessionStore = userSessionStore
        
        homeserverSubject = .init(LoginHomeserver(address: appSettings.defaultHomeserverAddress,
                                                  loginMode: .unknown))
        
        let oidcConfiguration = OidcConfiguration(clientName: InfoPlistReader.main.bundleDisplayName,
                                                  redirectUri: appSettings.oidcRedirectURL.absoluteString,
                                                  clientUri: appSettings.websiteURL.absoluteString,
                                                  logoUri: appSettings.logoURL.absoluteString,
                                                  tosUri: appSettings.acceptableUseURL.absoluteString,
                                                  policyUri: appSettings.privacyURL.absoluteString,
                                                  contacts: [appSettings.supportEmailAddress],
                                                  staticRegistrations: appSettings.oidcStaticRegistrations.mapKeys { $0.absoluteString })
        
        authenticationService = AuthenticationService(basePath: userSessionStore.baseDirectory.path,
                                                      passphrase: passphrase,
                                                      userAgent: UserAgentBuilder.makeASCIIUserAgent(),
                                                      oidcConfiguration: oidcConfiguration,
                                                      customSlidingSyncProxy: appSettings.slidingSyncProxyURL?.absoluteString,
                                                      sessionDelegate: userSessionStore.clientSessionDelegate,
                                                      crossProcessRefreshLockId: InfoPlistReader.main.bundleIdentifier)
    }
    
    // MARK: - Public
    
    func configure(for homeserverAddress: String) async -> Result<Void, AuthenticationServiceError> {
        do {
            var homeserver = LoginHomeserver(address: homeserverAddress, loginMode: .unknown)
            
            try await Task.dispatch(on: .global()) {
                try self.authenticationService.configureHomeserver(serverNameOrHomeserverUrl: homeserverAddress)
            }
            
            if let details = authenticationService.homeserverDetails() {
                if details.supportsOidcLogin() {
                    homeserver.loginMode = .oidc
                } else if details.supportsPasswordLogin() {
                    homeserver.loginMode = .password
                } else {
                    homeserver.loginMode = .unsupported
                }
            }
            
            homeserverSubject.send(homeserver)
            return .success(())
        } catch AuthenticationError.SlidingSyncNotAvailable {
            MXLog.info("User entered a homeserver that isn't configured for sliding sync.")
            return .failure(.slidingSyncNotAvailable)
        } catch {
            MXLog.error("Failed configuring a server: \(error)")
            return .failure(.invalidHomeserverAddress)
        }
    }
    
    func urlForOIDCLogin() async -> Result<OIDCAuthenticationDataProxy, AuthenticationServiceError> {
        do {
            let oidcData = try await Task.dispatch(on: .global()) {
                try self.authenticationService.urlForOidcLogin()
            }
            return .success(OIDCAuthenticationDataProxy(underlyingData: oidcData))
        } catch {
            MXLog.error("Failed to get URL for OIDC login: \(error)")
            return .failure(.oidcError(.urlFailure))
        }
    }
    
    func loginWithOIDCCallback(_ callbackURL: URL, data: OIDCAuthenticationDataProxy) async -> Result<UserSessionProtocol, AuthenticationServiceError> {
        do {
            let client = try await Task.dispatch(on: .global()) {
                try self.authenticationService.loginWithOidcCallback(authenticationData: data.underlyingData, callbackUrl: callbackURL.absoluteString)
            }
            return await userSession(for: client)
        } catch AuthenticationError.OidcCancelled {
            return .failure(.oidcError(.userCancellation))
        } catch {
            MXLog.error("Login with OIDC failed: \(error)")
            return .failure(.failedLoggingIn)
        }
    }
    
    func login(username: String, password: String, initialDeviceName: String?, deviceID: String?) async -> Result<UserSessionProtocol, AuthenticationServiceError> {
        do {
            let client = try await Task.dispatch(on: .global()) {
                try self.authenticationService.login(username: username,
                                                     password: password,
                                                     initialDeviceName: initialDeviceName,
                                                     deviceId: deviceID)
            }
            
            return await userSession(for: client)
        } catch {
            MXLog.error("Failed logging in with error: \(error)")
            guard let error = error as? AuthenticationError else { return .failure(.failedLoggingIn) }
            
            if error.isElementWaitlist {
                return .failure(.isOnWaitlist)
            }
            
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
        switch await userSessionStore.userSession(for: client, passphrase: passphrase) {
        case .success(let clientProxy):
            return .success(clientProxy)
        case .failure:
            return .failure(.failedLoggingIn)
        }
    }
}

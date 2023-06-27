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
    
    private let homeserverSubject: CurrentValueSubject<LoginHomeserver, Never> = .init(LoginHomeserver(address: ServiceLocator.shared.settings.defaultHomeserverAddress,
                                                                                                       loginMode: .unknown))
    var homeserver: CurrentValuePublisher<LoginHomeserver, Never> { homeserverSubject.asCurrentValuePublisher() }
    
    init(userSessionStore: UserSessionStoreProtocol) {
        self.userSessionStore = userSessionStore
        
        // guard let settings = ServiceLocator.shared.settings else { fatalError("The settings must be set.") }
        // let oidcConfiguration = OidcConfiguration(clientName: InfoPlistReader.main.bundleDisplayName,
        //                                           redirectUri: settings.oidcRedirectURL.absoluteString,
        //                                           clientUri: settings.oidcClientURL.absoluteString,
        //                                           tosUri: settings.oidcTermsURL.absoluteString,
        //                                           policyUri: settings.oidcPolicyURL.absoluteString,
        //                                           staticRegistrations: settings.oidcStaticRegistrations.mapKeys { $0.absoluteString })
        
        authenticationService = AuthenticationService(basePath: userSessionStore.baseDirectory.path,
                                                      passphrase: nil,
                                                      userAgent: UserAgentBuilder.makeASCIIUserAgent(),
                                                      // oidcConfiguration: oidcConfiguration,
                                                      customSlidingSyncProxy: ServiceLocator.shared.settings.slidingSyncProxyURL?.absoluteString)
    }
    
    // MARK: - Public
    
    func configure(for homeserverAddress: String) async -> Result<Void, AuthenticationServiceError> {
        do {
            var homeserver = LoginHomeserver(address: homeserverAddress, loginMode: .unknown)
            
            try await Task.dispatch(on: .global()) {
                try self.authenticationService.configureHomeserver(serverNameOrHomeserverUrl: homeserverAddress)
            }
            
            if let details = authenticationService.homeserverDetails() {
                if details.authenticationIssuer() != nil {
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
        .failure(.oidcError(.notSupported))
//        do {
//            let oidcData = try await Task.dispatch(on: .global()) {
//                try self.authenticationService.urlForOidcLogin()
//            }
//            return .success(OIDCAuthenticationDataProxy(underlyingData: oidcData))
//        } catch {
//            MXLog.error("Failed to get URL for OIDC login: \(error)")
//            return .failure(.oidcError(.urlFailure))
//        }
    }
    
    func loginWithOIDCCallback(_ callbackURL: URL, data: OIDCAuthenticationDataProxy) async -> Result<UserSessionProtocol, AuthenticationServiceError> {
        .failure(.oidcError(.notSupported))
//        do {
//            let client = try await Task.dispatch(on: .global()) {
//                try self.authenticationService.loginWithOidcCallback(authenticationData: data.underlyingData, callbackUrl: callbackURL.absoluteString)
//            }
//            return await userSession(for: client)
//        } catch AuthenticationError.OidcCancelled {
//            return .failure(.oidcError(.userCancellation))
//        } catch {
//            MXLog.error("Login with OIDC failed: \(error)")
//            return .failure(.failedLoggingIn)
//        }
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
        switch await userSessionStore.userSession(for: client) {
        case .success(let clientProxy):
            return .success(clientProxy)
        case .failure:
            return .failure(.failedLoggingIn)
        }
    }
}

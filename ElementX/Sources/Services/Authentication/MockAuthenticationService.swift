//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import Foundation
import MatrixRustSDK

class MockAuthenticationService: AuthenticationServiceProtocol {
    let validCredentials = (username: "alice", password: "12345678")
    
    private let homeserverSubject: CurrentValueSubject<LoginHomeserver, Never>
    var homeserver: CurrentValuePublisher<LoginHomeserver, Never> { homeserverSubject.asCurrentValuePublisher() }
    
    init(homeserver: LoginHomeserver = .mockMatrixDotOrg) {
        homeserverSubject = .init(homeserver)
    }
    
    func configure(for homeserverAddress: String) async -> Result<Void, AuthenticationServiceError> {
        // Map the address to the mock homeservers
        if LoginHomeserver.mockMatrixDotOrg.address.contains(homeserverAddress) {
            homeserverSubject.send(.mockMatrixDotOrg)
            return .success(())
        } else if LoginHomeserver.mockOIDC.address.contains(homeserverAddress) {
            homeserverSubject.send(.mockOIDC)
            return .success(())
        } else if LoginHomeserver.mockBasicServer.address.contains(homeserverAddress) {
            homeserverSubject.send(.mockBasicServer)
            return .success(())
        } else if LoginHomeserver.mockUnsupported.address.contains(homeserverAddress) {
            homeserverSubject.send(.mockUnsupported)
            return .success(())
        } else {
            // Otherwise fail with an invalid server.
            return .failure(.invalidServer)
        }
    }
    
    func urlForOIDCLogin() async -> Result<OIDCAuthorizationDataProxy, AuthenticationServiceError> {
        .failure(.oidcError(.notSupported))
    }
    
    func abortOIDCLogin(data: OIDCAuthorizationDataProxy) async { }
    
    func loginWithOIDCCallback(_ callbackURL: URL, data: OIDCAuthorizationDataProxy) async -> Result<UserSessionProtocol, AuthenticationServiceError> {
        .failure(.oidcError(.notSupported))
    }
    
    func login(username: String, password: String, initialDeviceName: String?, deviceID: String?) async -> Result<UserSessionProtocol, AuthenticationServiceError> {
        // Login only succeeds if the username and password match the valid credentials property
        guard username == validCredentials.username, password == validCredentials.password else {
            return .failure(.invalidCredentials)
        }
        
        let userSession = UserSessionMock(.init(clientProxy: ClientProxyMock(.init(userID: username))))
        return .success(userSession)
    }
    
    func completeWebRegistration(using credentials: WebRegistrationCredentials) async -> Result<any UserSessionProtocol, AuthenticationServiceError> {
        .failure(.failedLoggingIn)
    }
}

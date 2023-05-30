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

class MockAuthenticationServiceProxy: AuthenticationServiceProxyProtocol {
    let validCredentials = (username: "alice", password: "12345678")
    
    @PublishedOnSet
    private(set) var homeserver: LoginHomeserver
    var homeserverPublisher: AnyPublisher<LoginHomeserver, Never> { $homeserver }
    
    init(homeserver: LoginHomeserver = .mockMatrixDotOrg) {
        self.homeserver = homeserver
    }
    
    func configure(for homeserverAddress: String) async -> Result<Void, AuthenticationServiceError> {
        // Map the address to the mock homeservers
        if LoginHomeserver.mockMatrixDotOrg.address.contains(homeserverAddress) {
            homeserver = .mockMatrixDotOrg
            return .success(())
        } else if LoginHomeserver.mockOIDC.address.contains(homeserverAddress) {
            homeserver = .mockOIDC
            return .success(())
        } else if LoginHomeserver.mockBasicServer.address.contains(homeserverAddress) {
            homeserver = .mockBasicServer
            return .success(())
        } else if LoginHomeserver.mockUnsupported.address.contains(homeserverAddress) {
            homeserver = .mockUnsupported
            return .success(())
        } else {
            // Otherwise fail with an invalid server.
            return .failure(.invalidServer)
        }
    }
    
    func urlForOIDCLogin() async -> Result<OIDCAuthenticationDataProxy, AuthenticationServiceError> {
        .failure(.oidcError(.notSupported))
    }
    
    func loginWithOIDCCallback(_ callbackURL: URL, data: OIDCAuthenticationDataProxy) async -> Result<UserSessionProtocol, AuthenticationServiceError> {
        .failure(.oidcError(.notSupported))
    }
    
    func login(username: String, password: String, initialDeviceName: String?, deviceId: String?) async -> Result<UserSessionProtocol, AuthenticationServiceError> {
        // Login only succeeds if the username and password match the valid credentials property
        guard username == validCredentials.username, password == validCredentials.password else {
            return .failure(.invalidCredentials)
        }
        
        let userSession = MockUserSession(clientProxy: MockClientProxy(userID: username),
                                          mediaProvider: MockMediaProvider())
        return .success(userSession)
    }
}

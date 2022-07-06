//
//  MockAuthenticationService.swift
//  ElementX
//
//  Created by Doug on 29/06/2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Foundation

class MockAuthenticationServiceProxy: AuthenticationServiceProxyProtocol {
    let validCredentials = (username: "alice", password: "12345678")
    private(set) var homeserver: LoginHomeserver = .mockMatrixDotOrg
    
    func useServer(for homeserverAddress: String) async -> Result<Void, AuthenticationServiceError> {
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
    
    func login(username: String, password: String) async -> Result<UserSessionProtocol, AuthenticationServiceError> {
        // Login only succeeds if the username and password match the valid credentials property
        guard username == validCredentials.username, password == validCredentials.password else {
            return .failure(.invalidCredentials)
        }
        
        let userSession = MockUserSession(clientProxy: MockClientProxy(userIdentifier: username),
                                          mediaProvider: MockMediaProvider())
        return .success(userSession)
    }
}

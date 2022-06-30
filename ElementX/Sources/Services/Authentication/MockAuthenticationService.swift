//
//  MockAuthenticationService.swift
//  ElementX
//
//  Created by Doug on 29/06/2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Foundation

class MockAuthenticationService: AuthenticationServiceProtocol {
    let validCredentials = (username: "alice", password: "12345678")
    private(set) var homeserver: LoginHomeserver = .mockMatrixDotOrg
    
    func usernameIsMatrixID(_ username: String) -> Bool {
        let range = NSRange(location: 0, length: username.count)
        
        let detector = try? NSRegularExpression(pattern: MatrixEntityRegex.userId.rawValue, options: .caseInsensitive)
        return detector?.numberOfMatches(in: username, range: range) ?? 0 == 1
    }
    
    func startLogin(for homeserverAddress: String) async -> Result<Void, AuthenticationServiceError> {
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
        }
        
        return .failure(.invalidServer)
    }
    
    func login(username: String, password: String) async -> Result<UserSessionProtocol, AuthenticationServiceError> {
        guard username == validCredentials.username, password == validCredentials.password else {
            return .failure(.failedLoggingIn)
        }
        
        let userSession = MockUserSession(clientProxy: MockClientProxy(userIdentifier: username),
                                          mediaProvider: MockMediaProvider())
        return .success(userSession)
    }
}

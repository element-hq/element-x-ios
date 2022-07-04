//
//  AuthenticationServiceProtocol.swift
//  ElementX
//
//  Created by Doug on 29/06/2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Foundation

enum AuthenticationServiceError: Error {
    case invalidServer
    case invalidCredentials
    case accountDeactivated
    case failedLoggingIn
}

@MainActor
protocol AuthenticationServiceProtocol {
    var homeserver: LoginHomeserver { get }
    
    /// Sets up the service for login on the specified homeserver address.
    func startLogin(for homeserverAddress: String) async -> Result<Void, AuthenticationServiceError>
    /// Performs a password login using the current homeserver.
    func login(username: String, password: String) async -> Result<UserSessionProtocol, AuthenticationServiceError>
}

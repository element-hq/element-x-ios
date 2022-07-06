//
//  AuthenticationService.swift
//  ElementX
//
//  Created by Doug on 29/06/2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Foundation
import MatrixRustSDK

class AuthenticationService: AuthenticationServiceProtocol {
    // MARK: - Properties
    
    // MARK: Private
    
    private(set) var homeserver = LoginHomeserver(address: BuildSettings.defaultHomeserverURLString)
    private let userSessionStore: UserSessionStoreProtocol
    
    // MARK: - Setup
    
    init(userSessionStore: UserSessionStoreProtocol) {
        self.userSessionStore = userSessionStore
    }
    
    // MARK: - Public
    
    func startLogin(for homeserverAddress: String) async -> Result<Void, AuthenticationServiceError> {
        homeserver = LoginHomeserver(address: homeserverAddress)
        return .success(())
    }
    
    func login(username: String, password: String) async -> Result<UserSessionProtocol, AuthenticationServiceError> {
        Benchmark.startTrackingForIdentifier("Login", message: "Started new login")
        
        // Workaround whilst the SDK requires a full MXID.
        let username = username.isMatrixUserID ? username : "@\(username):\(homeserver.address)"
        
        let basePath = userSessionStore.baseDirectoryPath(for: username)
        let builder = ClientBuilder()
            .basePath(path: basePath)
            .username(username: username)
        
        let loginTask: Task<Client, Error> = Task.detached {
            let client = try builder.build()
            try client.login(username: username, password: password)
            return client
        }
        
        switch await loginTask.result {
        case .success(let client):
            Benchmark.endTrackingForIdentifier("Login", message: "Finished login")
            return await userSession(for: client)
        case .failure(let error):
            Benchmark.endTrackingForIdentifier("Login", message: "Login failed")
            
            MXLog.error("Failed logging in with error: \(error)")
            guard let error = error as? ClientError else { return .failure(.failedLoggingIn) }
            
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

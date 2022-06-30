//
//  AuthenticationCoordinator.swift
//  ElementX
//
//  Created by Stefan Ceriu on 11.02.2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Foundation
import MatrixRustSDK

enum AuthenticationCoordinatorError: Error {
    case failedLoggingIn
}

@MainActor
protocol AuthenticationCoordinatorDelegate: AnyObject {
    
    func authenticationCoordinatorDidStartLoading(_ authenticationCoordinator: AuthenticationCoordinator)
    
    func authenticationCoordinator(_ authenticationCoordinator: AuthenticationCoordinator,
                                   didLoginWithSession userSession: UserSessionProtocol)
    
    func authenticationCoordinator(_ authenticationCoordinator: AuthenticationCoordinator,
                                   didFailWithError error: AuthenticationCoordinatorError)
}

class AuthenticationCoordinator: Coordinator {
    
    private let userSessionStore: UserSessionStoreProtocol
    private let navigationRouter: NavigationRouter
    
    private(set) var clientProxy: ClientProxyProtocol?
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: AuthenticationCoordinatorDelegate?
    
    init(userSessionStore: UserSessionStoreProtocol,
         navigationRouter: NavigationRouter) {
        self.userSessionStore = userSessionStore
        self.navigationRouter = navigationRouter
    }
    
    func start() {
        showSplashScreen()
    }
    
    // MARK: - Private
    
    private func showSplashScreen() {
        let coordinator = SplashScreenCoordinator()
        
        coordinator.callback = { [weak self] action in
            guard let self = self else { return }
            switch action {
            case .login:
                self.showLoginScreen()
            }
        }
        
        coordinator.start()
        add(childCoordinator: coordinator)
        
        navigationRouter.setRootModule(coordinator) { [weak self] in
            self?.remove(childCoordinator: coordinator)
        }
    }
    
    private func showLoginScreen() {
        let homeserver = LoginHomeserver(address: BuildSettings.defaultHomeserverURLString)
        let parameters = LoginCoordinatorParameters(navigationRouter: navigationRouter, homeserver: homeserver)
        let coordinator = LoginCoordinator(parameters: parameters)
        
        coordinator.callback = { [weak self, weak coordinator] action in
            guard let self = self, let coordinator = coordinator else {
                return
            }
            
            switch action {
            case .login(let username, let password):
                Task {
                    switch await self.login(username: username, password: password) {
                    case .success(let userSession):
                        self.delegate?.authenticationCoordinator(self, didLoginWithSession: userSession)
                        self.remove(childCoordinator: coordinator)
                        self.navigationRouter.dismissModule()
                    case .failure(let error):
                        self.delegate?.authenticationCoordinator(self, didFailWithError: error)
                        MXLog.error("Failed logging in user with error: \(error)")
                    }
                }
            case .continueWithOIDC:
                break
            }
        }
        
        coordinator.start()
        add(childCoordinator: coordinator)
        
        navigationRouter.push(coordinator) { [weak self] in
            self?.remove(childCoordinator: coordinator)
        }
    }
    
    private func login(username: String, password: String) async -> Result<UserSession, AuthenticationCoordinatorError> {
        Benchmark.startTrackingForIdentifier("Login", message: "Started new login")
        
        delegate?.authenticationCoordinatorDidStartLoading(self)
        
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
            return await userSession(for: client)
        case .failure(let error):
            MXLog.error("Failed logging in with error: \(error)")
            return .failure(.failedLoggingIn)
        }
    }
    
    private func userSession(for client: Client) async -> Result<UserSession, AuthenticationCoordinatorError> {
        switch await userSessionStore.userSession(for: client) {
        case .success(let clientProxy):
            return .success(clientProxy)
        case .failure:
            return .failure(.failedLoggingIn)
        }
    }
}

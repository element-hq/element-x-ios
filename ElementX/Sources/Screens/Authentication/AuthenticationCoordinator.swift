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
                                   didLoginWithSession userSession: UserSession)
    
    func authenticationCoordinator(_ authenticationCoordinator: AuthenticationCoordinator,
                                   didFailWithError error: AuthenticationCoordinatorError)
}

class AuthenticationCoordinator: Coordinator {
    
    private let userSessionStore: UserSessionStore
    private let navigationRouter: NavigationRouter
    
    private(set) var clientProxy: ClientProxyProtocol?
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: AuthenticationCoordinatorDelegate?
    
    init(userSessionStore: UserSessionStore,
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
            case .register:
                fatalError("Not implemented")
            }
        }
        
        coordinator.start()
        add(childCoordinator: coordinator)
        
        navigationRouter.setRootModule(coordinator) { [weak self] in
            self?.remove(childCoordinator: coordinator)
        }
    }
    
    private func showLoginScreen() {
        let parameters = LoginScreenCoordinatorParameters()
        let coordinator = LoginScreenCoordinator(parameters: parameters)
        
        coordinator.callback = { [weak self, weak coordinator] action in
            guard let self = self, let coordinator = coordinator else {
                return
            }
            
            switch action {
            case .login(let result):
                Task {
                    switch await self.login(username: result.username, password: result.password) {
                    case .success(let userSession):
                        self.delegate?.authenticationCoordinator(self, didLoginWithSession: userSession)
                        self.remove(childCoordinator: coordinator)
                        self.navigationRouter.dismissModule()
                    case .failure(let error):
                        self.delegate?.authenticationCoordinator(self, didFailWithError: error)
                        MXLog.error("Failed logging in user with error: \(error)")
                    }
                }
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
        let loginTask = Task.detached {
            try loginNewClient(basePath: basePath,
                               username: username,
                               password: password)
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

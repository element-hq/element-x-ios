//
//  AuthenticationCoordinator.swift
//  ElementX
//
//  Created by Stefan Ceriu on 11.02.2022.
//  Copyright © 2022 Element. All rights reserved.
//

import UIKit
import MatrixRustSDK

@MainActor
protocol AuthenticationCoordinatorDelegate: AnyObject {
    func authenticationCoordinator(_ authenticationCoordinator: AuthenticationCoordinator,
                                   didLoginWithSession userSession: UserSessionProtocol)
}

class AuthenticationCoordinator: Coordinator, Presentable {
    
    private let authenticationService: AuthenticationServiceProtocol
    private let navigationRouter: NavigationRouter
    
    private(set) var clientProxy: ClientProxyProtocol?
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: AuthenticationCoordinatorDelegate?
    
    init(authenticationService: AuthenticationServiceProtocol,
         navigationRouter: NavigationRouter) {
        self.authenticationService = authenticationService
        self.navigationRouter = navigationRouter
    }
    
    func start() {
        showSplashScreen()
    }
    
    func toPresentable() -> UIViewController {
        navigationRouter.toPresentable()
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
        let parameters = LoginCoordinatorParameters(authenticationService: authenticationService,
                                                    navigationRouter: navigationRouter)
        let coordinator = LoginCoordinator(parameters: parameters)
        
        coordinator.callback = { [weak self, weak coordinator] action in
            guard let self = self, let coordinator = coordinator else { return }
            
            switch action {
            case .signedIn(let userSession):
                self.delegate?.authenticationCoordinator(self, didLoginWithSession: userSession)
                self.remove(childCoordinator: coordinator)
                self.navigationRouter.dismissModule()
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
}

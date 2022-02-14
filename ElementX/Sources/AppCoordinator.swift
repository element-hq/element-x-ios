//
//  AppCoordinator.swift
//  ElementX
//
//  Created by Stefan Ceriu on 11.02.2022.
//

import UIKit

class AppCoordinator: AuthenticationCoordinatorDelegate, Coordinator {
    private let window: UIWindow
    
    private let mainNavigationController: UINavigationController
    private let splashViewController: UIViewController
    
    private let navigationRouter: NavigationRouter
    
    private let keychainController: KeychainControllerProtocol
    private let authenticationCoordinator: AuthenticationCoordinator!
    
    var childCoordinators: [Coordinator] = []
    
    init() {
        splashViewController = SplashViewController()
        mainNavigationController = UINavigationController(rootViewController: splashViewController)
        mainNavigationController.setNavigationBarHidden(true, animated: false)
        window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = mainNavigationController
        
        navigationRouter = NavigationRouter(navigationController: mainNavigationController)
        
        guard let bundleIdentifier = Bundle.main.bundleIdentifier else {
            fatalError("Should have a valid bundle identifier at this point")
        }
        
        keychainController = KeychainController(identifier: bundleIdentifier)
        authenticationCoordinator = AuthenticationCoordinator(keychainController: keychainController,
                                                              navigationRouter: navigationRouter)
        authenticationCoordinator.delegate = self
    }
    
    func start() {
        window.makeKeyAndVisible()
        authenticationCoordinator.start()
    }
    
    // MARK: - AuthenticationCoordinatorDelegate
    
    func authenticationCoordinator(_ authenticationCoordinator: AuthenticationCoordinator, didFailWithError error: AuthenticationCoordinatorError) {
        
    }
    
    func authenticationCoordinatorDidSetupUserSession(_ authenticationCoordinator: AuthenticationCoordinator) {
        presentHomeScreen()
    }
    
    func authenticationCoordinatorDidTearDownUserSession(_ authenticationCoordinator: AuthenticationCoordinator) {
        
    }
    
    // MARK: - Private
    
    private func presentHomeScreen() {
        guard let userSession = authenticationCoordinator.userSession else {
            fatalError("User session should be already setup at this point")
        }
        
        let parameters = HomeScreenCoordinatorParameters(userSession: userSession)
        let coordinator = HomeScreenCoordinator(parameters: parameters)
        
        add(childCoordinator: coordinator)
        navigationRouter.setRootModule(coordinator)
    }
    
    private func restart() {
        
    }
}

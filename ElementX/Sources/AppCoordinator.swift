//
//  AppCoordinator.swift
//  ElementX
//
//  Created by Stefan Ceriu on 11.02.2022.
//

import UIKit
import Kingfisher

class AppCoordinator: AuthenticationCoordinatorDelegate, Coordinator {
    private let window: UIWindow
    
    private let mainNavigationController: UINavigationController
    private let splashViewController: UIViewController
    
    private let navigationRouter: NavigationRouter
    
    private let keychainController: KeychainControllerProtocol
    private let authenticationCoordinator: AuthenticationCoordinator!
    
    private var loadingActivity: Activity?
    private var errorActivity: Activity?
    
    var childCoordinators: [Coordinator] = []
    
    init() {
        splashViewController = SplashViewController()
        mainNavigationController = UINavigationController(rootViewController: splashViewController)
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
    
    func authenticationCoordinatorDidStartLoading(_ authenticationCoordinator: AuthenticationCoordinator) {
        showLoadingIndicator()
    }
    
    func authenticationCoordinator(_ authenticationCoordinator: AuthenticationCoordinator, didFailWithError error: AuthenticationCoordinatorError) {
        hideLoadingIndicator()
        showLoginErrorToast()
    }
    
    func authenticationCoordinatorDidSetupUserSession(_ authenticationCoordinator: AuthenticationCoordinator) {
        presentHomeScreen()
    }
    
    func authenticationCoordinatorDidTearDownUserSession(_ authenticationCoordinator: AuthenticationCoordinator) {
        if let presentedCoordinator = childCoordinators.first {
            remove(childCoordinator: presentedCoordinator)
        }

        mainNavigationController.setViewControllers([splashViewController], animated: false)
        authenticationCoordinator.start()
    }
    
    // MARK: - Private
    
    private func presentHomeScreen() {
        
        hideLoadingIndicator()
        
        guard let userSession = authenticationCoordinator.userSession else {
            fatalError("User session should be already setup at this point")
        }
        
        let parameters = HomeScreenCoordinatorParameters(userSession: userSession)
        let coordinator = HomeScreenCoordinator(parameters: parameters, imageCache: ImageCache.default)
        
        coordinator.completion = { [weak self] result in
            switch result {
            case .logout:
                self?.authenticationCoordinator.logout()
            case .selectRoom(let roomIdentifier):
                self?.presentRoomWithIdentifier(roomIdentifier)
            }
        }
        
        add(childCoordinator: coordinator)
        navigationRouter.setRootModule(coordinator)
    }
    
    private func presentRoomWithIdentifier(_ roomIdentifier: String) {
        guard let userSession = authenticationCoordinator.userSession else {
            fatalError("User session should be already setup at this point")
        }
        
        showLoadingIndicator()
        
        userSession.getRoomList { [weak self] rooms in
            guard let self = self else { return }
            
            self.hideLoadingIndicator()
            
            guard let roomProxy = rooms.filter({ $0.id == roomIdentifier}).first else {
                MXLog.error("Invalid room identifier: \(roomIdentifier)")
                return
            }
            
            let parameters = RoomScreenCoordinatorParameters(roomProxy: roomProxy)
            let coordinator = RoomScreenCoordinator(parameters: parameters)
            
            coordinator.completion = { _ in
                
            }
            
            self.add(childCoordinator: coordinator)
            self.navigationRouter.push(coordinator) { [weak self] in
                guard let self = self else { return }
                
                self.remove(childCoordinator: coordinator)
            }
        }
    }
    
    private func showLoadingIndicator() {
        let presenter = FullscreenLoadingActivityPresenter(label: "Loading",
                                                           on: mainNavigationController)
        
        let request = ActivityRequest(
            presenter: presenter,
            dismissal: .manual
        )
        
        loadingActivity = ActivityCenter.shared.add(request)
    }
    
    private func hideLoadingIndicator() {
        loadingActivity = nil
    }
    
    private func showLoginErrorToast() {
        let presenter = ToastActivityPresenter(viewState: .init(style: .success, label: "Failed logging in"),
                                               navigationController: mainNavigationController)
        
        let request = ActivityRequest(
            presenter: presenter,
            dismissal: .timeout(3.0)
        )
        
        errorActivity = ActivityCenter.shared.add(request)
    }
}

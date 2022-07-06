//
//  AuthenticationCoordinator.swift
//  ElementX
//
//  Created by Stefan Ceriu on 11.02.2022.
//  Copyright © 2022 Element. All rights reserved.
//

import MatrixRustSDK
import UIKit

@MainActor
protocol AuthenticationCoordinatorDelegate: AnyObject {
    func authenticationCoordinator(_ authenticationCoordinator: AuthenticationCoordinator,
                                   didLoginWithSession userSession: UserSessionProtocol)
}

class AuthenticationCoordinator: Coordinator, Presentable {
    private let authenticationService: AuthenticationServiceProxyProtocol
    private let navigationRouter: NavigationRouter
    private var indicatorPresenter: UserIndicatorTypePresenterProtocol
    private var activityIndicator: UserIndicator?
    
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: AuthenticationCoordinatorDelegate?
    
    init(authenticationService: AuthenticationServiceProxyProtocol,
         navigationRouter: NavigationRouter) {
        self.authenticationService = authenticationService
        self.navigationRouter = navigationRouter
        
        indicatorPresenter = UserIndicatorTypePresenter(presentingViewController: navigationRouter.toPresentable())
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
                Task { await self.startAuthentication() }
            }
        }
        
        coordinator.start()
        add(childCoordinator: coordinator)
        
        navigationRouter.setRootModule(coordinator) { [weak self] in
            self?.remove(childCoordinator: coordinator)
        }
    }
    
    private func startAuthentication() async {
        startLoading()
        
        switch await authenticationService.useServer(for: BuildSettings.defaultHomeserverURLString) {
        case .success:
            stopLoading()
            showLoginScreen()
        case .failure:
            stopLoading()
            showServerSelectionScreen()
        }
    }
    
    private func showServerSelectionScreen() {
        let parameters = ServerSelectionCoordinatorParameters(authenticationService: authenticationService,
                                                              hasModalPresentation: false)
        let coordinator = ServerSelectionCoordinator(parameters: parameters)
        
        coordinator.callback = { [weak self] action in
            guard let self = self else { return }
            
            switch action {
            case .updated:
                self.showLoginScreen()
            case .dismiss:
                MXLog.failure("[AuthenticationCoordinator] ServerSelectionScreen is requesting dismiss when part of a stack.")
            }
        }
        
        coordinator.start()
        add(childCoordinator: coordinator)
        
        navigationRouter.push(coordinator) { [weak self] in
            self?.remove(childCoordinator: coordinator)
        }
    }
    
    private func showLoginScreen() {
        let parameters = LoginCoordinatorParameters(authenticationService: authenticationService,
                                                    navigationRouter: navigationRouter)
        let coordinator = LoginCoordinator(parameters: parameters)
        
        coordinator.callback = { [weak self] action in
            guard let self = self else { return }
            
            switch action {
            case .signedIn(let userSession):
                self.delegate?.authenticationCoordinator(self, didLoginWithSession: userSession)
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
    
    /// Show a blocking activity indicator.
    private func startLoading() {
        activityIndicator = indicatorPresenter.present(.loading(label: ElementL10n.loading, isInteractionBlocking: true))
    }
    
    /// Hide the currently displayed activity indicator.
    private func stopLoading() {
        activityIndicator = nil
    }
}

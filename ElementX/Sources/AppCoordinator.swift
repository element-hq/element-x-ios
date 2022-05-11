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
    
    private let memberDetailProviderManager: MemberDetailProviderManager
        
    private var indicatorPresenter: UserIndicatorTypePresenterProtocol
    private var loadingIndicator: UserIndicator?
    private var errorIndicator: UserIndicator?
    
    var childCoordinators: [Coordinator] = []
    
    init() {
        splashViewController = SplashViewController()
        mainNavigationController = UINavigationController(rootViewController: splashViewController)
        window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = mainNavigationController
        
        navigationRouter = NavigationRouter(navigationController: mainNavigationController)
        
        memberDetailProviderManager = MemberDetailProviderManager()
        
        indicatorPresenter = UserIndicatorTypePresenter(presentingViewController: mainNavigationController)
        
        guard let bundleIdentifier = Bundle.main.bundleIdentifier else {
            fatalError("Should have a valid bundle identifier at this point")
        }
        
        keychainController = KeychainController(identifier: bundleIdentifier)
        authenticationCoordinator = AuthenticationCoordinator(keychainController: keychainController,
                                                              navigationRouter: navigationRouter)
        authenticationCoordinator.delegate = self
        
        let loggerConfiguration = MXLogConfiguration()
        loggerConfiguration.logLevel = .verbose
        MXLog.configure(loggerConfiguration)
        
        // Benchmark.trackingEnabled = true
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
        
        let parameters = HomeScreenCoordinatorParameters(userSession: userSession,
                                                         mediaProvider: userSession.mediaProvider,
                                                         attributedStringBuilder: AttributedStringBuilder(),
                                                         memberDetailProviderManager: memberDetailProviderManager)
        let coordinator = HomeScreenCoordinator(parameters: parameters)
        
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
        
        guard let roomProxy = userSession.rooms.first(where: { $0.id == roomIdentifier }) else {
            MXLog.error("Invalid room identifier: \(roomIdentifier)")
            return
        }
        
        let memberDetailProvider = memberDetailProviderManager.memberDetailProviderForRoomProxy(roomProxy)
        
        let timelineItemFactory = RoomTimelineItemFactory(mediaProvider: userSession.mediaProvider,
                                                          memberDetailProvider: memberDetailProvider,
                                                          attributedStringBuilder: AttributedStringBuilder())
        
        let timelineController = RoomTimelineController(timelineProvider: RoomTimelineProvider(roomProxy: roomProxy),
                                                        timelineItemFactory: timelineItemFactory,
                                                        mediaProvider: userSession.mediaProvider,
                                                        memberDetailProvider: memberDetailProvider)
        
        let parameters = RoomScreenCoordinatorParameters(timelineController: timelineController,
                                                         roomName: roomProxy.name)
        let coordinator = RoomScreenCoordinator(parameters: parameters)
        
        self.add(childCoordinator: coordinator)
        self.navigationRouter.push(coordinator) { [weak self] in
            guard let self = self else { return }
            
            self.remove(childCoordinator: coordinator)
        }
    }
    
    private func showLoadingIndicator() {
        loadingIndicator = indicatorPresenter.present(.loading(label: "Loading", isInteractionBlocking: true))
    }
    
    private func hideLoadingIndicator() {
        loadingIndicator = nil
    }
    
    private func showLoginErrorToast() {
        errorIndicator = indicatorPresenter.present(.success(label: "Failed logging in"))
    }
}

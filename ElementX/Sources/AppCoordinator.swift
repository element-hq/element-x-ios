//
//  AppCoordinator.swift
//  ElementX
//
//  Created by Stefan Ceriu on 11.02.2022.
//  Copyright © 2022 Element. All rights reserved.
//

import UIKit
import Kingfisher

class AppCoordinator: AuthenticationCoordinatorDelegate, Coordinator {
    private let window: UIWindow
    
    private var stateMachine: AppCoordinatorStateMachine
    
    private let mainNavigationController: UINavigationController
    private let splashViewController: UIViewController
    
    private let navigationRouter: NavigationRouter
    
    private let keychainController: KeychainControllerProtocol
    private let authenticationCoordinator: AuthenticationCoordinator!
    
    private var userSession: UserSession!
    
    private let memberDetailProviderManager: MemberDetailProviderManager
    
    private var indicatorPresenter: UserIndicatorTypePresenterProtocol
    private var loadingIndicator: UserIndicator?
    private var errorIndicator: UserIndicator?
    
    var childCoordinators: [Coordinator] = []
    
    init() {
        stateMachine = AppCoordinatorStateMachine()
        
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
        
        setupStateMachine()
        
        let loggerConfiguration = MXLogConfiguration()
        loggerConfiguration.logLevel = .verbose
        // Redirect NSLogs to files only if we are not debugging
        if isatty(STDERR_FILENO) == 0 {
            loggerConfiguration.redirectLogsToFiles = true
        }
        MXLog.configure(loggerConfiguration)
        
        // Benchmark.trackingEnabled = true
    }
    
    func start() {
        stateMachine.processEvent(.start)
    }
    
    // MARK: - AuthenticationCoordinatorDelegate
    
    func authenticationCoordinatorDidStartLoading(_ authenticationCoordinator: AuthenticationCoordinator) {
        stateMachine.processEvent(.attemptedSignIn)
    }
    
    func authenticationCoordinator(_ authenticationCoordinator: AuthenticationCoordinator, didFailWithError error: AuthenticationCoordinatorError) {
        stateMachine.processEvent(.failedSigningIn)
    }
    
    func authenticationCoordinatorDidSetupClientProxy(_ authenticationCoordinator: AuthenticationCoordinator) {
        stateMachine.processEvent(.succeededSigningIn)
    }
    
    func authenticationCoordinatorDidTearDownClientProxy(_ authenticationCoordinator: AuthenticationCoordinator) {
        stateMachine.processEvent(.succeededSigningOut)
    }
    
    // MARK: - Private
    
    // swiftlint:disable cyclomatic_complexity
    private func setupStateMachine() {
        stateMachine.addTransitionHandler { [weak self] context in
            guard let self = self else { return }
                
            switch (context.fromState, context.event, context.toState) {
            case (.initial, .start, .signedOut):
                self.window.makeKeyAndVisible()
                self.authenticationCoordinator.start()
            case (.signedOut, .attemptedSignIn, .signingIn):
                self.showLoadingIndicator()
            case (.signingIn, .failedSigningIn, .signedOut):
                self.hideLoadingIndicator()
                self.showLoginErrorToast()
            case (.signingIn, .succeededSigningIn, .signedIn):
                self.hideLoadingIndicator()
                self.setupUserSession()
            case (.signedIn, .showHomeScreen, .homeScreen):
                self.presentHomeScreen()
            case(_, _, .roomScreen(let roomId)):
                self.presentRoomWithIdentifier(roomId)
            case(.roomScreen, .dismissedRoomScreen, .homeScreen):
                self.tearDownDismissedRoomScreen()
            case (_, .attemptSignOut, .signingOut):
                self.authenticationCoordinator.logout()
            case (.signingOut, .succeededSigningOut, .signedOut):
                self.tearDownUserSession()
            case (.signingOut, .failedSigningOut, _):
                self.showLogoutErrorToast()
            default:
                fatalError("Unknown transition: \(context)")
            }
        }
        
        stateMachine.addErrorHandler { context in
            fatalError("Failed transition with context: \(context)")
        }
    }
    // swiftlint:enable cyclomatic_complexity
    
    private func setupUserSession() {
        guard let clientProxy = authenticationCoordinator.clientProxy else {
            fatalError("User session should be setup at this point")
        }
        
        userSession = .init(clientProxy: clientProxy,
                            mediaProvider: MediaProvider(clientProxy: clientProxy, imageCache: ImageCache.default))
        
        stateMachine.processEvent(.showHomeScreen)
    }
    
    private func tearDownUserSession() {
        if let presentedCoordinator = childCoordinators.first {
            remove(childCoordinator: presentedCoordinator)
        }
        
        userSession = nil
        
        mainNavigationController.setViewControllers([splashViewController], animated: false)
        authenticationCoordinator.start()
    }
    
    private func presentHomeScreen() {
        let parameters = HomeScreenCoordinatorParameters(userSession: userSession,
                                                         attributedStringBuilder: AttributedStringBuilder(),
                                                         memberDetailProviderManager: memberDetailProviderManager)
        let coordinator = HomeScreenCoordinator(parameters: parameters)
        
        coordinator.callback = { [weak self] action in
            guard let self = self else { return }
            
            switch action {
            case .logout:
                self.stateMachine.processEvent(.attemptSignOut)
            case .selectRoom(let roomIdentifier):
                self.stateMachine.processEvent(.showRoomScreen(roomId: roomIdentifier))
            }
        }
        
        add(childCoordinator: coordinator)
        navigationRouter.setRootModule(coordinator)
    }
    
    private func presentRoomWithIdentifier(_ roomIdentifier: String) {
        guard let roomProxy = userSession.clientProxy.rooms.first(where: { $0.id == roomIdentifier }) else {
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
                                                         roomName: roomProxy.displayName ?? roomProxy.name)
        let coordinator = RoomScreenCoordinator(parameters: parameters)
        
        add(childCoordinator: coordinator)
        navigationRouter.push(coordinator) { [weak self] in
            guard let self = self else { return }
            self.stateMachine.processEvent(.dismissedRoomScreen)
        }
    }
    
    private func tearDownDismissedRoomScreen() {
        guard let coordinator = childCoordinators.last as? RoomScreenCoordinator else {
            fatalError("Invalid coordinator hierarchy: \(childCoordinators)")
        }
        
        remove(childCoordinator: coordinator)
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
    
    private func showLogoutErrorToast() {
        errorIndicator = indicatorPresenter.present(.success(label: "Failed logging out"))
    }
}

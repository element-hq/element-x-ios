//
//  AppCoordinator.swift
//  ElementX
//
//  Created by Stefan Ceriu on 11.02.2022.
//  Copyright © 2022 Element. All rights reserved.
//

import UIKit

class AppCoordinator: AuthenticationCoordinatorDelegate, Coordinator {
    private let window: UIWindow
    
    private var stateMachine: AppCoordinatorStateMachine
    
    private let mainNavigationController: UINavigationController
    private let splashViewController: UIViewController
    
    private let navigationRouter: NavigationRouter
    
    private let userSessionStore: UserSessionStoreProtocol
    
    private var userSession: UserSessionProtocol!
    
    private let memberDetailProviderManager: MemberDetailProviderManager

    private let bugReportService: BugReportServiceProtocol
    private let screenshotDetector: ScreenshotDetector
    private let backgroundTaskService: BackgroundTaskServiceProtocol

    private var indicatorPresenter: UserIndicatorTypePresenterProtocol
    private var loadingIndicator: UserIndicator?
    private var statusIndicator: UserIndicator?
    
    var childCoordinators: [Coordinator] = []
    
    init() {
        stateMachine = AppCoordinatorStateMachine()

        do {
            bugReportService = try BugReportService(withBaseUrlString: BuildSettings.bugReportServiceBaseUrlString,
                                                    sentryEndpoint: BuildSettings.bugReportSentryEndpoint)
        } catch {
            fatalError(error.localizedDescription)
        }

        splashViewController = SplashViewController()
        mainNavigationController = ElementNavigationController(rootViewController: splashViewController)
        window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = mainNavigationController
        window.tintColor = .element.accent
        
        navigationRouter = NavigationRouter(navigationController: mainNavigationController)
        
        memberDetailProviderManager = MemberDetailProviderManager()
        
        indicatorPresenter = UserIndicatorTypePresenter(presentingViewController: mainNavigationController)
        
        guard let bundleIdentifier = Bundle.main.bundleIdentifier else {
            fatalError("Should have a valid bundle identifier at this point")
        }

        backgroundTaskService = UIKitBackgroundTaskService(withApplication: UIApplication.shared)
        
        userSessionStore = UserSessionStore(bundleIdentifier: bundleIdentifier,
                                            backgroundTaskService: backgroundTaskService)

        screenshotDetector = ScreenshotDetector()
        screenshotDetector.callback = processScreenshotDetection
        
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
        window.makeKeyAndVisible()
        stateMachine.processEvent(userSessionStore.hasSessions ? .startWithExistingSession : .startWithAuthentication)
    }
    
    // MARK: - AuthenticationCoordinatorDelegate
    
    func authenticationCoordinatorDidStartLoading(_ authenticationCoordinator: AuthenticationCoordinator) {
        stateMachine.processEvent(.attemptedSignIn)
    }
    
    func authenticationCoordinator(_ authenticationCoordinator: AuthenticationCoordinator, didLoginWithSession userSession: UserSessionProtocol) {
        self.userSession = userSession
        remove(childCoordinator: authenticationCoordinator)
        stateMachine.processEvent(.succeededSigningIn)
    }
    
    func authenticationCoordinator(_ authenticationCoordinator: AuthenticationCoordinator, didFailWithError error: AuthenticationCoordinatorError) {
        stateMachine.processEvent(.failedSigningIn)
    }
    
    // MARK: - Private
    
    // swiftlint:disable cyclomatic_complexity function_body_length
    private func setupStateMachine() {
        stateMachine.addTransitionHandler { [weak self] context in
            guard let self = self else { return }
            
            switch (context.fromState, context.event, context.toState) {
            case (.initial, .startWithAuthentication, .signedOut):
                self.startAuthentication()
            case (.signedOut, .attemptedSignIn, .signingIn):
                self.showLoadingIndicator()
            case (.signingIn, .failedSigningIn, .signedOut):
                self.hideLoadingIndicator()
                self.showLoginErrorToast()
            case (.signingIn, .succeededSigningIn, .homeScreen):
                self.hideLoadingIndicator()
                self.presentHomeScreen()
            
            case (.initial, .startWithExistingSession, .restoringSession):
                self.showLoadingIndicator()
                self.restoreUserSession()
            case (.restoringSession, .failedRestoringSession, .signedOut):
                self.hideLoadingIndicator()
                self.showLoginErrorToast()
            case (.restoringSession, .succeededRestoringSession, .homeScreen):
                self.hideLoadingIndicator()
                self.presentHomeScreen()
            
            case(_, _, .roomScreen(let roomId)):
                self.presentRoomWithIdentifier(roomId)
            case(.roomScreen, .dismissedRoomScreen, .homeScreen):
                self.tearDownDismissedRoomScreen()
            case (_, .attemptSignOut, .signingOut):
                self.userSessionStore.logout(userSession: self.userSession)
                self.stateMachine.processEvent(.succeededSigningOut)
            case (.signingOut, .succeededSigningOut, .signedOut):
                self.tearDownUserSession()
            case (.signingOut, .failedSigningOut, _):
                self.showLogoutErrorToast()
            case (.homeScreen, .showSettingsScreen, .settingsScreen):
                self.presentSettingsScreen()
            case (.settingsScreen, .dismissedSettingsScreen, .homeScreen):
                self.tearDownDismissedSettingsScreen()
            default:
                fatalError("Unknown transition: \(context)")
            }
        }
        
        stateMachine.addErrorHandler { context in
            fatalError("Failed transition with context: \(context)")
        }
    }
    // swiftlint:enable cyclomatic_complexity function_body_length
    
    private func restoreUserSession() {
        Task {
            switch await userSessionStore.restoreUserSession() {
            case .success(let userSession):
                self.userSession = userSession
                stateMachine.processEvent(.succeededRestoringSession)
            case .failure:
                MXLog.error("Failed to restore an existing session.")
                stateMachine.processEvent(.failedRestoringSession)
            }
        }
    }
    
    private func startAuthentication() {
        let coordinator = AuthenticationCoordinator(userSessionStore: userSessionStore,
                                                    navigationRouter: navigationRouter)
        coordinator.delegate = self
        
        add(childCoordinator: coordinator)
        coordinator.start()
    }
    
    private func tearDownUserSession() {
        if let presentedCoordinator = childCoordinators.first {
            remove(childCoordinator: presentedCoordinator)
        }
        
        userSession = nil
        
        mainNavigationController.setViewControllers([splashViewController], animated: false)
        
        startAuthentication()
    }
    
    private func presentHomeScreen() {
        let parameters = HomeScreenCoordinatorParameters(userSession: userSession,
                                                         attributedStringBuilder: AttributedStringBuilder(),
                                                         memberDetailProviderManager: memberDetailProviderManager)
        let coordinator = HomeScreenCoordinator(parameters: parameters)
        
        coordinator.callback = { [weak self] action in
            guard let self = self else { return }
            
            switch action {
            case .presentRoom(let roomIdentifier):
                self.stateMachine.processEvent(.showRoomScreen(roomId: roomIdentifier))
            case .presentSettings:
                self.stateMachine.processEvent(.showSettingsScreen)
            }
        }
        
        add(childCoordinator: coordinator)
        navigationRouter.setRootModule(coordinator)

        if bugReportService.crashedLastRun {
            showCrashPopup()
        }
    }

    private func presentSettingsScreen() {
        let parameters = SettingsCoordinatorParameters(navigationRouter: navigationRouter,
                                                       bugReportService: bugReportService)
        let coordinator = SettingsCoordinator(parameters: parameters)
        coordinator.callback = { [weak self] action in
            guard let self = self else { return }
            switch action {
            case .logout:
                self.stateMachine.processEvent(.attemptSignOut)
            }
        }

        add(childCoordinator: coordinator)
        coordinator.start()
        navigationRouter.push(coordinator) { [weak self] in
            guard let self = self else { return }

            self.stateMachine.processEvent(.dismissedSettingsScreen)
        }
    }
    
    private func presentRoomWithIdentifier(_ roomIdentifier: String) {
        guard let roomProxy = userSession.clientProxy.rooms.first(where: { $0.id == roomIdentifier }) else {
            MXLog.error("Invalid room identifier: \(roomIdentifier)")
            return
        }
        let userId = userSession.clientProxy.userIdentifier
        
        let memberDetailProvider = memberDetailProviderManager.memberDetailProviderForRoomProxy(roomProxy)
        
        let timelineItemFactory = RoomTimelineItemFactory(mediaProvider: userSession.mediaProvider,
                                                          memberDetailProvider: memberDetailProvider,
                                                          attributedStringBuilder: AttributedStringBuilder())
        
        let timelineController = RoomTimelineController(userId: userId,
                                                        timelineProvider: RoomTimelineProvider(roomProxy: roomProxy),
                                                        timelineItemFactory: timelineItemFactory,
                                                        mediaProvider: userSession.mediaProvider,
                                                        memberDetailProvider: memberDetailProvider)
        
        let parameters = RoomScreenCoordinatorParameters(timelineController: timelineController,
                                                         roomName: roomProxy.displayName ?? roomProxy.name,
                                                         roomAvatar: userSession.mediaProvider.imageFromURLString(roomProxy.avatarURL),
                                                         roomEncryptionBadge: roomProxy.encryptionBadgeImage)
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

    private func tearDownDismissedSettingsScreen() {
        guard let coordinator = childCoordinators.last as? SettingsCoordinator else {
            fatalError("Invalid coordinator hierarchy: \(childCoordinators)")
        }

        remove(childCoordinator: coordinator)
    }
    
    private func showLoadingIndicator() {
        loadingIndicator = indicatorPresenter.present(.loading(label: ElementL10n.loading, isInteractionBlocking: true))
    }
    
    private func hideLoadingIndicator() {
        loadingIndicator = nil
    }
    
    private func showLoginErrorToast() {
        statusIndicator = indicatorPresenter.present(.error(label: "Failed logging in"))
    }
    
    private func showLogoutErrorToast() {
        statusIndicator = indicatorPresenter.present(.error(label: "Failed logging out"))
    }

    private func showCrashPopup() {
        let alert = UIAlertController(title: nil,
                                      message: ElementL10n.sendBugReportAppCrashed,
                                      preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: ElementL10n.no, style: .cancel))
        alert.addAction(UIAlertAction(title: ElementL10n.yes, style: .default) { [weak self] _ in
            self?.presentBugReportScreen()
        })

        navigationRouter.present(alert, animated: true)
    }

    private func processScreenshotDetection(image: UIImage?, error: Error?) {
        MXLog.debug("[AppCoordinator] processScreenshotDetection: \(String(describing: image)), error: \(String(describing: error))")

        let alert = UIAlertController(title: ElementL10n.screenshotDetectedTitle,
                                      message: ElementL10n.screenshotDetectedMessage,
                                      preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: ElementL10n.no, style: .cancel))
        alert.addAction(UIAlertAction(title: ElementL10n.yes, style: .default) { [weak self] _ in
            self?.presentBugReportScreen(for: image)
        })

        navigationRouter.present(alert, animated: true)
    }

    private func presentBugReportScreen(for image: UIImage? = nil) {
        let parameters = BugReportCoordinatorParameters(bugReportService: bugReportService,
                                                        screenshot: image)
        let coordinator = BugReportCoordinator(parameters: parameters)
        coordinator.completion = { [weak self, weak coordinator] in
            guard let self = self, let coordinator = coordinator else { return }
            self.navigationRouter.dismissModule(animated: true)
            self.remove(childCoordinator: coordinator)
        }

        add(childCoordinator: coordinator)
        coordinator.start()
        let navController = ElementNavigationController(rootViewController: coordinator.toPresentable())
        navController.navigationBar.topItem?.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel,
                                                                                 target: self,
                                                                                 action: #selector(dismissBugReportScreen))
        navController.isModalInPresentation = true
        navigationRouter.present(navController, animated: true)
    }

    @objc
    private func dismissBugReportScreen() {
        MXLog.debug("[AppCoorrdinator] dismissBugReportScreen")

        guard let bugReportCoordinator = childCoordinators.first(where: { $0 is BugReportCoordinator }) else {
            return
        }

        navigationRouter.dismissModule()
        remove(childCoordinator: bugReportCoordinator)
    }
}

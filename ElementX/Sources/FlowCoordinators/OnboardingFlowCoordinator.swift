//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import Foundation
import SwiftState

enum OnboardingFlowCoordinatorAction {
    case logout
}

class OnboardingFlowCoordinator: FlowCoordinatorProtocol {
    private let userSession: UserSessionProtocol
    private let appLockService: AppLockServiceProtocol
    private let analyticsService: AnalyticsService
    private let appSettings: AppSettings
    private let notificationManager: NotificationManagerProtocol
    private let rootNavigationStackCoordinator: NavigationStackCoordinator
    private let userIndicatorController: UserIndicatorControllerProtocol
    private let windowManager: WindowManagerProtocol
    private let isNewLogin: Bool
    
    private var navigationStackCoordinator: NavigationStackCoordinator!
    
    enum State: StateType {
        case initial
        case identityConfirmation
        case identityConfirmed
        case appLockSetup
        case analyticsPrompt
        case notificationPermissions
        case finished
    }
    
    enum Event: EventType {
        case next
        case nextSkippingIdentityConfimed
    }
    
    private let stateMachine: StateMachine<State, Event>
    private var cancellables = Set<AnyCancellable>()
    
    // periphery: ignore - used to store the coordinator to avoid deallocation
    private var appLockFlowCoordinator: AppLockSetupFlowCoordinator?
    
    private let actionsSubject: PassthroughSubject<OnboardingFlowCoordinatorAction, Never> = .init()
    var actions: AnyPublisher<OnboardingFlowCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    private var verificationStateCancellable: AnyCancellable?
    
    init(userSession: UserSessionProtocol,
         appLockService: AppLockServiceProtocol,
         analyticsService: AnalyticsService,
         appSettings: AppSettings,
         notificationManager: NotificationManagerProtocol,
         navigationStackCoordinator: NavigationStackCoordinator,
         userIndicatorController: UserIndicatorControllerProtocol,
         windowManager: WindowManagerProtocol,
         isNewLogin: Bool) {
        self.userSession = userSession
        self.appLockService = appLockService
        self.analyticsService = analyticsService
        self.appSettings = appSettings
        self.notificationManager = notificationManager
        self.userIndicatorController = userIndicatorController
        self.windowManager = windowManager
        self.isNewLogin = isNewLogin
        
        rootNavigationStackCoordinator = navigationStackCoordinator
        self.navigationStackCoordinator = NavigationStackCoordinator()
        
        stateMachine = .init(state: .initial)
        
        // Verification can change as part of the onboarding flow by verifying with
        // another device, using a recovery key or by resetting one's crypto identity.
        // It can also happen that onboarding started before it had a chance to update,
        // usually seen when registering a new account.
        // Handle all those cases here instead of spreading them throughout the code.
        verificationStateCancellable = userSession.sessionSecurityStatePublisher
            .map(\.verificationState)
            .removeDuplicates()
            .sink { [weak self] value in
                guard let self,
                      value == .verified,
                      stateMachine.state == .identityConfirmation else { return }
                
                appSettings.hasRunIdentityConfirmationOnboarding = true
                stateMachine.tryEvent(.nextSkippingIdentityConfimed)
                self.verificationStateCancellable = nil
            }
    }
    
    var shouldStart: Bool {
        guard stateMachine.state == .initial, !ProcessInfo.isRunningIntegrationTests else {
            return false
        }
        
        return isNewLogin || requiresVerification || requiresAppLockSetup || requiresAnalyticsSetup || requiresNotificationsSetup
    }
    
    func start() {
        guard shouldStart else {
            fatalError("This flow coordinator shouldn't have been started")
        }
        
        configureStateMachine()
        
        rootNavigationStackCoordinator.setFullScreenCoverCoordinator(navigationStackCoordinator, animated: !isNewLogin)

        stateMachine.tryEvent(.next)
    }
    
    func handleAppRoute(_ appRoute: AppRoute, animated: Bool) {
        fatalError()
    }
    
    func clearRoute(animated: Bool) {
        fatalError()
    }
    
    // MARK: - Private
    
    private var requiresVerification: Bool {
        // We want to make sure onboarding finishes but also every time the user becomes unverified (e.g. account reset)
        !appSettings.hasRunIdentityConfirmationOnboarding || userSession.sessionSecurityStatePublisher.value.verificationState == .unverified
    }
    
    private var requiresAppLockSetup: Bool {
        appSettings.appLockIsMandatory && !appLockService.isEnabled
    }
    
    private var requiresAnalyticsSetup: Bool {
        analyticsService.shouldShowAnalyticsPrompt
    }
    
    private var requiresNotificationsSetup: Bool {
        !appSettings.hasRunNotificationPermissionsOnboarding
    }
    
    private func configureStateMachine() {
        stateMachine.addRouteMapping { [weak self] event, fromState, _ in
            guard let self else {
                return nil
            }
            
            switch (fromState, requiresVerification, requiresAppLockSetup, requiresAnalyticsSetup, requiresNotificationsSetup) {
            case (.initial, true, _, _, _):
                return .identityConfirmation
            case (.initial, false, true, _, _):
                return .appLockSetup
            case (.initial, false, false, true, _):
                return .analyticsPrompt
            case (.initial, false, false, false, true):
                return .notificationPermissions
            case (.initial, false, false, false, false):
                return .finished
                
            case (.identityConfirmation, _, _, _, _):
                if event == .nextSkippingIdentityConfimed {
                    // Used when the verification state has updated to verified
                    // after starting the onboarding flow
                    switch (requiresAppLockSetup, requiresAnalyticsSetup, requiresNotificationsSetup) {
                    case (true, _, _):
                        return .appLockSetup
                    case (false, true, _):
                        return .analyticsPrompt
                    case (false, false, true):
                        return .notificationPermissions
                    case (false, false, false):
                        return .finished
                    }
                } else {
                    return .identityConfirmed
                }
            case (.identityConfirmed, _, true, _, _):
                return .appLockSetup
            case (.identityConfirmed, _, false, true, _):
                return .analyticsPrompt
            case (.identityConfirmed, _, false, false, true):
                return .notificationPermissions
            case (.identityConfirmed, _, false, false, false):
                return .finished
                
            case (.appLockSetup, _, _, true, _):
                return .analyticsPrompt
            case (.appLockSetup, _, _, false, true):
                return .notificationPermissions
            case (.appLockSetup, _, _, false, false):
                return .finished
                
            case (.analyticsPrompt, _, _, _, true):
                return .notificationPermissions
            case (.analyticsPrompt, _, _, _, false):
                return .finished
                
            case (.notificationPermissions, _, _, _, _):
                return .finished
            
            default:
                return nil
            }
        }
        
        stateMachine.addAnyHandler(.any => .any) { [weak self] context in
            guard let self else { return }
            
            switch (context.fromState, context.event, context.toState) {
            case (_, _, .identityConfirmation):
                presentIdentityConfirmationScreen()
            case (_, _, .identityConfirmed):
                presentIdentityConfirmedScreen()
            case (_, _, .appLockSetup):
                presentAppLockSetupFlow()
            case (_, _, .analyticsPrompt):
                presentAnalyticsPromptScreen()
            case (_, _, .notificationPermissions):
                presentNotificationPermissionsScreen()
            case (_, _, .finished):
                rootNavigationStackCoordinator.setFullScreenCoverCoordinator(nil)
            default:
                fatalError("Unknown transition: \(context)")
            }
        }
        
        stateMachine.addErrorHandler { context in
            fatalError("Unexpected transition: \(context)")
        }
    }
    
    private func presentIdentityConfirmationScreen() {
        let parameters = IdentityConfirmationScreenCoordinatorParameters(userSession: userSession,
                                                                         appSettings: appSettings,
                                                                         userIndicatorController: userIndicatorController)
        
        let coordinator = IdentityConfirmationScreenCoordinator(parameters: parameters)
        coordinator.actionsPublisher.sink { [weak self] action in
            guard let self else { return }
            
            switch action {
            case .otherDevice:
                Task {
                    await self.presentSessionVerificationScreen()
                }
            case .recoveryKey:
                presentRecoveryKeyScreen()
            case .skip:
                appSettings.hasRunIdentityConfirmationOnboarding = true
                stateMachine.tryEvent(.nextSkippingIdentityConfimed)
            case .reset:
                presentEncryptionResetScreen()
            case .logout:
                actionsSubject.send(.logout)
            }
        }
        .store(in: &cancellables)
        
        presentCoordinator(coordinator)
    }
    
    private func presentSessionVerificationScreen() async {
        guard case let .success(sessionVerificationController) = await userSession.clientProxy.sessionVerificationControllerProxy() else {
            fatalError("The sessionVerificationController should aways be valid at this point")
        }
        
        let parameters = SessionVerificationScreenCoordinatorParameters(sessionVerificationControllerProxy: sessionVerificationController)
        
        let coordinator = SessionVerificationScreenCoordinator(parameters: parameters)
        
        coordinator.actions
            .sink { action in
                switch action {
                case .done:
                    break // Moving to next state is handled by the global session verification listener
                }
            }
            .store(in: &cancellables)
        
        presentCoordinator(coordinator)
    }
    
    private func presentRecoveryKeyScreen() {
        let parameters = SecureBackupRecoveryKeyScreenCoordinatorParameters(secureBackupController: userSession.clientProxy.secureBackupController,
                                                                            userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                                                            isModallyPresented: false)
        
        let coordinator = SecureBackupRecoveryKeyScreenCoordinator(parameters: parameters)
        
        coordinator.actions
            .sink { [weak self] action in
                guard let self else { return }
                
                switch action {
                case .recoveryFixed:
                    break // Moving to next state is Handled by the global session verification listener
                case .resetEncryption:
                    presentEncryptionResetScreen()
                default:
                    MXLog.error("Unexpected recovery action: \(action)")
                }
            }
            .store(in: &cancellables)
        
        presentCoordinator(coordinator)
    }
    
    private func presentEncryptionResetScreen() {
        let resetNavigationStackCoordinator = NavigationStackCoordinator()
        
        let coordinator = EncryptionResetScreenCoordinator(parameters: .init(clientProxy: userSession.clientProxy,
                                                                             navigationStackCoordinator: resetNavigationStackCoordinator,
                                                                             userIndicatorController: userIndicatorController))
        
        coordinator.actionsPublisher.sink { [weak self] action in
            guard let self else { return }
            
            switch action {
            case .cancel:
                navigationStackCoordinator.setSheetCoordinator(nil)
            case .requestOIDCAuthorisation(let url):
                presentOIDCAuthorisationScreen(url: url)
            case .resetFinished:
                // Moving to next state is handled by the global session verification listener
                navigationStackCoordinator.setSheetCoordinator(nil)
            }
        }
        .store(in: &cancellables)
        
        resetNavigationStackCoordinator.setRootCoordinator(coordinator)
        
        navigationStackCoordinator.setSheetCoordinator(resetNavigationStackCoordinator)
    }
    
    private func presentIdentityConfirmedScreen() {
        let coordinator = IdentityConfirmedScreenCoordinator(parameters: .init())
        coordinator.actionsPublisher
            .sink { [weak self] action in
                guard let self else { return }
                
                switch action {
                case .done:
                    stateMachine.tryEvent(.next)
                }
            }
            .store(in: &cancellables)
        
        presentCoordinator(coordinator)
    }
    
    private func presentAppLockSetupFlow() {
        let coordinator = AppLockSetupFlowCoordinator(presentingFlow: .onboarding,
                                                      appLockService: appLockService,
                                                      navigationStackCoordinator: navigationStackCoordinator)
        coordinator.actions.sink { [weak self] action in
            guard let self else { return }
            switch action {
            case .complete:
                appLockFlowCoordinator = nil
                stateMachine.tryEvent(.next)
            case .forceLogout:
                fatalError("The PIN creation flow should not fail.")
            }
        }
        .store(in: &cancellables)
        
        appLockFlowCoordinator = coordinator
        coordinator.start()
    }

    private func presentAnalyticsPromptScreen() {
        let coordinator = AnalyticsPromptScreenCoordinator(analytics: analyticsService, termsURL: appSettings.analyticsConfiguration.termsURL)
        
        coordinator.actions
            .sink { [weak self] action in
                guard let self else { return }
                switch action {
                case .done:
                    stateMachine.tryEvent(.next)
                }
            }
            .store(in: &cancellables)
        
        presentCoordinator(coordinator)
    }
    
    private func presentNotificationPermissionsScreen() {
        let coordinator = NotificationPermissionsScreenCoordinator(parameters: .init(notificationManager: notificationManager))
        
        coordinator.actions
            .sink { [weak self] action in
                guard let self else { return }
                switch action {
                case .done:
                    appSettings.hasRunNotificationPermissionsOnboarding = true
                    stateMachine.tryEvent(.next)
                }
            }
            .store(in: &cancellables)
        
        presentCoordinator(coordinator)
    }
    
    private func presentCoordinator(_ coordinator: CoordinatorProtocol, dismissalCallback: (() -> Void)? = nil) {
        if navigationStackCoordinator.rootCoordinator == nil {
            navigationStackCoordinator.setRootCoordinator(coordinator, dismissalCallback: dismissalCallback)
        } else {
            navigationStackCoordinator.push(coordinator, dismissalCallback: dismissalCallback)
        }
    }
    
    private var accountSettingsPresenter: OIDCAccountSettingsPresenter?
    private func presentOIDCAuthorisationScreen(url: URL) {
        // Note to anyone in the future if you come back here to make this open in Safari instead of a WAS.
        // As of iOS 16, there is an issue on the simulator with accessing the cookie but it works on a device. 🤷‍♂️
        accountSettingsPresenter = OIDCAccountSettingsPresenter(accountURL: url, presentationAnchor: windowManager.mainWindow)
        accountSettingsPresenter?.start()
    }
}

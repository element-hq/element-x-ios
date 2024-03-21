//
// Copyright 2024 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Combine
import Foundation
import SwiftState

class OnboardingFlowCoordinator: FlowCoordinatorProtocol {
    private let userSession: UserSessionProtocol
    private let appLockService: AppLockServiceProtocol
    private let analyticsService: AnalyticsService
    private let appSettings: AppSettings
    private let notificationManager: NotificationManagerProtocol
    private let rootNavigationStackCoordinator: NavigationStackCoordinator
    private let userIndicatorController: UserIndicatorControllerProtocol
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
    }
    
    private let stateMachine: StateMachine<State, Event>
    private var cancellables = Set<AnyCancellable>()
    
    // periphery: ignore - used to store the coordinator to avoid deallocation
    private var appLockFlowCoordinator: AppLockSetupFlowCoordinator?
    
    init(userSession: UserSessionProtocol,
         appLockService: AppLockServiceProtocol,
         analyticsService: AnalyticsService,
         appSettings: AppSettings,
         notificationManager: NotificationManagerProtocol,
         navigationStackCoordinator: NavigationStackCoordinator,
         userIndicatorController: UserIndicatorControllerProtocol,
         isNewLogin: Bool) {
        self.userSession = userSession
        self.appLockService = appLockService
        self.analyticsService = analyticsService
        self.appSettings = appSettings
        self.notificationManager = notificationManager
        self.userIndicatorController = userIndicatorController
        self.isNewLogin = isNewLogin
        
        rootNavigationStackCoordinator = navigationStackCoordinator
        self.navigationStackCoordinator = NavigationStackCoordinator()
        
        stateMachine = .init(state: .initial)
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
        
        stateMachine.tryEvent(.next)
        
        rootNavigationStackCoordinator.setFullScreenCoverCoordinator(navigationStackCoordinator, animated: !isNewLogin)
    }
    
    func handleAppRoute(_ appRoute: AppRoute, animated: Bool) {
        fatalError()
    }
    
    func clearRoute(animated: Bool) {
        fatalError()
    }
    
    // MARK: - Private
    
    private var requiresVerification: Bool {
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
        let requiresNotificationsSetup = requiresNotificationsSetup
        
        stateMachine.addRouteMapping { [weak self] _, fromState, _ in
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
                
            case (.identityConfirmation, _, _, _, _):
                return .identityConfirmed
                
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
            .sink { [weak self] action in
                guard let self else { return }
                
                switch action {
                case .done:
                    appSettings.hasRunIdentityConfirmationOnboarding = true
                    stateMachine.tryEvent(.next)
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
                    appSettings.hasRunIdentityConfirmationOnboarding = true
                    stateMachine.tryEvent(.next)
                default:
                    fatalError("Other flows shouldn't be possible")
                }
            }
            .store(in: &cancellables)
        
        presentCoordinator(coordinator)
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
    
    private func presentCoordinator(_ coordinator: CoordinatorProtocol) {
        if navigationStackCoordinator.rootCoordinator == nil {
            navigationStackCoordinator.setRootCoordinator(coordinator)
        } else {
            navigationStackCoordinator.push(coordinator)
        }
    }
}

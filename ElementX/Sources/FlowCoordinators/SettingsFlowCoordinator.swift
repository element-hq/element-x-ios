//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import SwiftUI

enum SettingsFlowCoordinatorAction {
    case presentedSettings
    case dismissedSettings
    case runLogoutFlow
    case clearCache
    /// Logout without a confirmation. The user forgot their PIN.
    case forceLogout
}

struct SettingsFlowCoordinatorParameters {
    let userSession: UserSessionProtocol
    let windowManager: WindowManagerProtocol
    let appLockService: AppLockServiceProtocol
    let bugReportService: BugReportServiceProtocol
    let notificationSettings: NotificationSettingsProxyProtocol
    let secureBackupController: SecureBackupControllerProtocol
    let appSettings: AppSettings
    let navigationSplitCoordinator: NavigationSplitCoordinator
    let userIndicatorController: UserIndicatorControllerProtocol
}

class SettingsFlowCoordinator: FlowCoordinatorProtocol {
    private let parameters: SettingsFlowCoordinatorParameters
    
    private var navigationStackCoordinator: NavigationStackCoordinator!
    
    private var cancellables = Set<AnyCancellable>()
    
    // periphery:ignore - retaining purpose
    private var appLockSetupFlowCoordinator: AppLockSetupFlowCoordinator?
    
    // periphery:ignore - retaining purpose
    private var bugReportFlowCoordinator: BugReportFlowCoordinator?
    
    private let actionsSubject: PassthroughSubject<SettingsFlowCoordinatorAction, Never> = .init()
    var actions: AnyPublisher<SettingsFlowCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: SettingsFlowCoordinatorParameters) {
        self.parameters = parameters
    }
    
    func start() {
        fatalError("Unavailable")
    }
    
    func handleAppRoute(_ appRoute: AppRoute, animated: Bool) {
        switch appRoute {
        case .settings:
            presentSettingsScreen(animated: animated)
        case .chatBackupSettings:
            if navigationStackCoordinator == nil {
                presentSettingsScreen(animated: animated)
            }
            
            // The navigation stack doesn't like it if the root and the push happen
            // on the same loop run
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                self.presentSecureBackupScreen(animated: animated)
            }
        default:
            break
        }
    }
    
    func clearRoute(animated: Bool) {
        fatalError("Unavailable")
    }
    
    // MARK: - Private
    
    private func presentSettingsScreen(animated: Bool) {
        navigationStackCoordinator = NavigationStackCoordinator()
        
        let settingsScreenCoordinator = SettingsScreenCoordinator(parameters: .init(userSession: parameters.userSession,
                                                                                    appSettings: parameters.appSettings))
        
        settingsScreenCoordinator.actions
            .sink { [weak self] action in
                guard let self else { return }
                
                switch action {
                case .dismiss:
                    parameters.navigationSplitCoordinator.setSheetCoordinator(nil)
                case .logout:
                    parameters.navigationSplitCoordinator.setSheetCoordinator(nil)
                    
                    // The settings sheet needs to be dismissed before the alert can be shown
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.actionsSubject.send(.runLogoutFlow)
                    }
                case .secureBackup:
                    presentSecureBackupScreen(animated: true)
                case .userDetails:
                    presentUserDetailsEditScreen()
                case let .manageAccount(url):
                    presentAccountManagementURL(url)
                case .analytics:
                    presentAnalyticsScreen()
                case .appLock:
                    presentAppLockSetupFlow()
                case .bugReport:
                    bugReportFlowCoordinator = BugReportFlowCoordinator(parameters: .init(presentationMode: .push(navigationStackCoordinator),
                                                                                          userIndicatorController: parameters.userIndicatorController,
                                                                                          bugReportService: parameters.bugReportService,
                                                                                          userSession: parameters.userSession))
                    bugReportFlowCoordinator?.start()
                case .about:
                    presentLegalInformationScreen()
                case .blockedUsers:
                    presentBlockedUsersScreen()
                case .notifications:
                    presentNotificationSettings()
                case .advancedSettings:
                    presentAdvancedSettings()
                case .developerOptions:
                    presentDeveloperOptions()
                case .deactivateAccount:
                    presentDeactivateAccount()
                }
            }
            .store(in: &cancellables)
        
        navigationStackCoordinator.setRootCoordinator(settingsScreenCoordinator, animated: animated)
        
        parameters.navigationSplitCoordinator.setSheetCoordinator(navigationStackCoordinator) { [weak self] in
            guard let self else { return }
            
            navigationStackCoordinator = nil
            actionsSubject.send(.dismissedSettings)
        }
        
        actionsSubject.send(.presentedSettings)
    }
    
    private func presentSecureBackupScreen(animated: Bool) {
        let coordinator = SecureBackupScreenCoordinator(parameters: .init(appSettings: parameters.appSettings,
                                                                          clientProxy: parameters.userSession.clientProxy,
                                                                          navigationStackCoordinator: navigationStackCoordinator,
                                                                          userIndicatorController: parameters.userIndicatorController))
        
        coordinator.actions.sink { [weak self] action in
            switch action {
            case .requestOIDCAuthorisation(let url):
                self?.presentAccountManagementURL(url)
            }
        }
        .store(in: &cancellables)
        
        navigationStackCoordinator.push(coordinator, animated: animated)
    }
    
    private func presentUserDetailsEditScreen() {
        let coordinator = UserDetailsEditScreenCoordinator(parameters: .init(orientationManager: parameters.windowManager,
                                                                             clientProxy: parameters.userSession.clientProxy,
                                                                             mediaProvider: parameters.userSession.mediaProvider,
                                                                             navigationStackCoordinator: navigationStackCoordinator,
                                                                             userIndicatorController: parameters.userIndicatorController))
        
        navigationStackCoordinator?.push(coordinator)
    }
    
    private func presentAnalyticsScreen() {
        let coordinator = AnalyticsSettingsScreenCoordinator(parameters: .init(appSettings: parameters.appSettings,
                                                                               analytics: ServiceLocator.shared.analytics))
        navigationStackCoordinator?.push(coordinator)
    }
    
    private func presentAppLockSetupFlow() {
        let coordinator = AppLockSetupFlowCoordinator(presentingFlow: .settings,
                                                      appLockService: parameters.appLockService,
                                                      navigationStackCoordinator: navigationStackCoordinator)
        coordinator.actions.sink { [weak self] action in
            guard let self else { return }
            switch action {
            case .complete:
                // The flow coordinator tidies up the stack, no need to do anything.
                appLockSetupFlowCoordinator = nil
            case .forceLogout:
                actionsSubject.send(.forceLogout)
            }
        }
        .store(in: &cancellables)
        
        appLockSetupFlowCoordinator = coordinator
        coordinator.start()
    }
    
    private func presentLegalInformationScreen() {
        navigationStackCoordinator.push(LegalInformationScreenCoordinator(appSettings: parameters.appSettings))
    }
    
    private func presentBlockedUsersScreen() {
        let coordinator = BlockedUsersScreenCoordinator(parameters: .init(hideProfiles: parameters.appSettings.hideIgnoredUserProfiles,
                                                                          clientProxy: parameters.userSession.clientProxy,
                                                                          mediaProvider: parameters.userSession.mediaProvider,
                                                                          userIndicatorController: parameters.userIndicatorController))
        navigationStackCoordinator.push(coordinator)
    }
        
    private func presentNotificationSettings() {
        let notificationParameters = NotificationSettingsScreenCoordinatorParameters(navigationStackCoordinator: navigationStackCoordinator,
                                                                                     userSession: parameters.userSession,
                                                                                     userNotificationCenter: UNUserNotificationCenter.current(),
                                                                                     notificationSettings: parameters.notificationSettings,
                                                                                     isModallyPresented: false)
        let coordinator = NotificationSettingsScreenCoordinator(parameters: notificationParameters)
        navigationStackCoordinator.push(coordinator)
    }
    
    private func presentAdvancedSettings() {
        let coordinator = AdvancedSettingsScreenCoordinator()
        navigationStackCoordinator.push(coordinator)
    }
    
    private func presentDeveloperOptions() {
        let coordinator = DeveloperOptionsScreenCoordinator(isUsingNativeSlidingSync: parameters.userSession.clientProxy.slidingSyncVersion == .native)
        
        coordinator.actions
            .sink { [weak self] action in
                guard let self else { return }
                
                switch action {
                case .clearCache:
                    actionsSubject.send(.clearCache)
                }
            }
            .store(in: &cancellables)
        
        navigationStackCoordinator.push(coordinator)
    }
    
    private func presentDeactivateAccount() {
        let parameters = DeactivateAccountScreenCoordinatorParameters(clientProxy: parameters.userSession.clientProxy,
                                                                      userIndicatorController: parameters.userIndicatorController)
        let coordinator = DeactivateAccountScreenCoordinator(parameters: parameters)
        
        coordinator.actionsPublisher
            .sink { [weak self] action in
                guard let self else { return }
                
                switch action {
                case .accountDeactivated:
                    actionsSubject.send(.forceLogout)
                }
            }
            .store(in: &cancellables)
        
        navigationStackCoordinator.push(coordinator)
    }

    // MARK: OIDC Account Management
        
    private var accountSettingsPresenter: OIDCAccountSettingsPresenter?
    private func presentAccountManagementURL(_ url: URL) {
        // Note to anyone in the future if you come back here to make this open in Safari instead of a WAS.
        // As of iOS 16, there is an issue on the simulator with accessing the cookie but it works on a device. 🤷‍♂️
        accountSettingsPresenter = OIDCAccountSettingsPresenter(accountURL: url, presentationAnchor: parameters.windowManager.mainWindow)
        accountSettingsPresenter?.start()
    }
}

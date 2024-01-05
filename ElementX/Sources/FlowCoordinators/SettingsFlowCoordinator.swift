//
// Copyright 2023 New Vector Ltd
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
    
    private let actionsSubject: PassthroughSubject<SettingsFlowCoordinatorAction, Never> = .init()
    var actions: AnyPublisher<SettingsFlowCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: SettingsFlowCoordinatorParameters) {
        self.parameters = parameters
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
    
    func clearRoute(animated: Bool) { }
    
    // MARK: - Private
    
    private func presentSettingsScreen(animated: Bool) {
        navigationStackCoordinator = NavigationStackCoordinator()
        
        let parameters = SettingsScreenCoordinatorParameters(userSession: parameters.userSession,
                                                             appSettings: parameters.appSettings)
        
        let settingsScreenCoordinator = SettingsScreenCoordinator(parameters: parameters)
        
        settingsScreenCoordinator.actions
            .sink { [weak self] action in
                guard let self else { return }
                
                switch action {
                case .dismiss:
                    self.parameters.navigationSplitCoordinator.setSheetCoordinator(nil)
                case .logout:
                    self.parameters.navigationSplitCoordinator.setSheetCoordinator(nil)
                    
                    // The settings sheet needs to be dismissed before the alert can be shown
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.actionsSubject.send(.runLogoutFlow)
                    }
                case .secureBackup:
                    presentSecureBackupScreen(animated: true)
                case .userDetails:
                    presentUserDetailsEditScreen()
                case .accountProfile:
                    presentAccountProfileURL()
                case .analytics:
                    presentAnalyticsScreen()
                case .appLock:
                    presentAppLockSetupFlow()
                case .bugReport:
                    presentBugReportScreen()
                case .about:
                    presentLegalInformationScreen()
                case .sessionVerification:
                    presentSessionVerificationScreen()
                case .accountSessions:
                    presentAccountSessionsListURL()
                case .notifications:
                    presentNotificationSettings()
                case .advancedSettings:
                    presentAdvancedSettings()
                case .developerOptions:
                    presentDeveloperOptions()
                }
            }
            .store(in: &cancellables)
        
        navigationStackCoordinator.setRootCoordinator(settingsScreenCoordinator, animated: animated)
        
        self.parameters.navigationSplitCoordinator.setSheetCoordinator(navigationStackCoordinator) { [weak self] in
            guard let self else { return }
            
            navigationStackCoordinator = nil
            actionsSubject.send(.dismissedSettings)
        }
        
        actionsSubject.send(.presentedSettings)
    }
    
    private func presentSecureBackupScreen(animated: Bool) {
        let coordinator = SecureBackupScreenCoordinator(parameters: .init(appSettings: parameters.appSettings,
                                                                          secureBackupController: parameters.userSession.clientProxy.secureBackupController,
                                                                          navigationStackCoordinator: navigationStackCoordinator,
                                                                          userIndicatorController: parameters.userIndicatorController))
        
        navigationStackCoordinator.push(coordinator, animated: animated)
    }
    
    private func presentUserDetailsEditScreen() {
        let coordinator = UserDetailsEditScreenCoordinator(parameters: .init(clientProxy: parameters.userSession.clientProxy,
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
    
    private func presentBugReportScreen() {
        let params = BugReportScreenCoordinatorParameters(bugReportService: parameters.bugReportService,
                                                          userID: parameters.userSession.userID,
                                                          deviceID: parameters.userSession.deviceID,
                                                          userIndicatorController: parameters.userIndicatorController,
                                                          screenshot: nil,
                                                          isModallyPresented: false)
        let coordinator = BugReportScreenCoordinator(parameters: params)
        coordinator.completion = { [weak self] result in
            switch result {
            case .finish:
                self?.showSuccess(label: L10n.actionDone)
            default:
                break
            }
            
            self?.navigationStackCoordinator.pop()
        }
        
        navigationStackCoordinator.push(coordinator)
    }
    
    private func presentLegalInformationScreen() {
        navigationStackCoordinator.push(LegalInformationScreenCoordinator(appSettings: parameters.appSettings))
    }
    
    private func presentSessionVerificationScreen() {
        guard let sessionVerificationController = parameters.userSession.sessionVerificationController else {
            fatalError("The sessionVerificationController should aways be valid at this point")
        }
        
        let verificationParameters = SessionVerificationScreenCoordinatorParameters(sessionVerificationControllerProxy: sessionVerificationController)
        let coordinator = SessionVerificationScreenCoordinator(parameters: verificationParameters)
        
        coordinator.actions
            .sink { [weak self] action in
                guard let self else { return }
                
                switch action {
                case .done:
                    navigationStackCoordinator.setSheetCoordinator(nil)
                }
            }
            .store(in: &cancellables)

        navigationStackCoordinator.setSheetCoordinator(coordinator) { [weak self] in
            self?.navigationStackCoordinator.setSheetCoordinator(nil)
        }
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
        let coordinator = DeveloperOptionsScreenCoordinator()
        
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

    private func showSuccess(label: String) {
        parameters.userIndicatorController.submitIndicator(UserIndicator(title: label))
    }
    
    // MARK: OIDC Account Management
    
    private func presentAccountProfileURL() {
        guard let url = parameters.userSession.clientProxy.accountURL(action: .profile) else {
            MXLog.error("Account URL is missing.")
            return
        }
        presentAccountManagementURL(url)
    }
    
    private func presentAccountSessionsListURL() {
        guard let url = parameters.userSession.clientProxy.accountURL(action: .sessionsList) else {
            MXLog.error("Account URL is missing.")
            return
        }
        presentAccountManagementURL(url)
    }
    
    private var accountSettingsPresenter: OIDCAccountSettingsPresenter?
    private func presentAccountManagementURL(_ url: URL) {
        // Note to anyone in the future if you come back here to make this open in Safari instead of a WAS.
        // As of iOS 16, there is an issue on the simulator with accessing the cookie but it works on a device. 🤷‍♂️
        accountSettingsPresenter = OIDCAccountSettingsPresenter(accountURL: url, presentationAnchor: parameters.windowManager.mainWindow)
        accountSettingsPresenter?.start()
    }
}

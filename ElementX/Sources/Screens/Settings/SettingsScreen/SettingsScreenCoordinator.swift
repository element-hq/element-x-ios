//
// Copyright 2022 New Vector Ltd
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

struct SettingsScreenCoordinatorParameters {
    weak var navigationStackCoordinator: NavigationStackCoordinator?
    let userIndicatorController: UserIndicatorControllerProtocol
    let userSession: UserSessionProtocol
    let appLockService: AppLockServiceProtocol
    let bugReportService: BugReportServiceProtocol
    let notificationSettings: NotificationSettingsProxyProtocol
    let secureBackupController: SecureBackupControllerProtocol
    let appSettings: AppSettings
}

enum SettingsScreenCoordinatorAction {
    case dismiss
    case logout
    case clearCache
    case secureBackup
    /// Logout without a confirmation. The user forgot their PIN.
    case forceLogout
}

final class SettingsScreenCoordinator: CoordinatorProtocol {
    private let parameters: SettingsScreenCoordinatorParameters
    private var viewModel: SettingsScreenViewModelProtocol
    
    private var appLockSetupFlowCoordinator: AppLockSetupFlowCoordinator?
    
    private let actionsSubject: PassthroughSubject<SettingsScreenCoordinatorAction, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
    
    var actions: AnyPublisher<SettingsScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Setup
    
    init(parameters: SettingsScreenCoordinatorParameters) {
        self.parameters = parameters
        
        viewModel = SettingsScreenViewModel(userSession: parameters.userSession,
                                            appSettings: parameters.appSettings)
        
        viewModel.actions
            .sink { [weak self] action in
                guard let self else { return }
                
                switch action {
                case .close:
                    actionsSubject.send(.dismiss)
                case .userDetails:
                    presentUserDetailsEditScreen()
                case .accountProfile:
                    presentAccountProfileURL()
                case .analytics:
                    presentAnalyticsScreen()
                case .appLock:
                    presentAppLockSetupFlow()
                case .reportBug:
                    presentBugReportScreen()
                case .about:
                    presentLegalInformationScreen()
                case .sessionVerification:
                    presentSessionVerificationScreen()
                case .secureBackup:
                    actionsSubject.send(.secureBackup)
                case .accountSessionsList:
                    presentAccountSessionsListURL()
                case .notifications:
                    presentNotificationSettings()
                case .advancedSettings:
                    self.presentAdvancedSettings()
                case .developerOptions:
                    presentDeveloperOptions()
                case .logout:
                    actionsSubject.send(.logout)
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public
    
    func toPresentable() -> AnyView {
        AnyView(SettingsScreen(context: viewModel.context))
    }
    
    // MARK: - OIDC Account Management
    
    private func presentAccountProfileURL() {
        guard let url = viewModel.context.viewState.accountProfileURL else {
            MXLog.error("Account URL is missing.")
            return
        }
        presentAccountManagementURL(url)
    }
    
    private func presentAccountSessionsListURL() {
        guard let url = viewModel.context.viewState.accountSessionsListURL else {
            MXLog.error("Account URL is missing.")
            return
        }
        presentAccountManagementURL(url)
    }
    
    private var accountSettingsPresenter: OIDCAccountSettingsPresenter?
    private func presentAccountManagementURL(_ url: URL) {
        guard let window = viewModel.context.viewState.window else {
            MXLog.error("The window is missing.")
            return
        }
        
        // Note to anyone in the future if you come back here to make this open in Safari instead of a WAS.
        // As of iOS 16, there is an issue on the simulator with accessing the cookie but it works on a device. 🤷‍♂️
        accountSettingsPresenter = OIDCAccountSettingsPresenter(accountURL: url, presentationAnchor: window)
        accountSettingsPresenter?.start()
    }
    
    // MARK: - Private
    
    private func presentUserDetailsEditScreen() {
        let coordinator = UserDetailsEditScreenCoordinator(parameters: .init(clientProxy: parameters.userSession.clientProxy,
                                                                             mediaProvider: parameters.userSession.mediaProvider,
                                                                             navigationStackCoordinator: parameters.navigationStackCoordinator,
                                                                             userIndicatorController: parameters.userIndicatorController))
        
        parameters.navigationStackCoordinator?.push(coordinator)
    }
    
    private func presentAnalyticsScreen() {
        let coordinator = AnalyticsSettingsScreenCoordinator(parameters: .init(appSettings: parameters.appSettings,
                                                                               analytics: ServiceLocator.shared.analytics))
        parameters.navigationStackCoordinator?.push(coordinator)
    }
    
    private func presentAppLockSetupFlow() {
        guard let navigationStackCoordinator = parameters.navigationStackCoordinator else {
            MXLog.error("The navigation stack has gone! 🌫️")
            return
        }
        
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
            
            self?.parameters.navigationStackCoordinator?.pop()
        }
        
        parameters.navigationStackCoordinator?.push(coordinator)
    }
    
    private func presentLegalInformationScreen() {
        parameters.navigationStackCoordinator?.push(LegalInformationScreenCoordinator(appSettings: parameters.appSettings))
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
                    parameters.navigationStackCoordinator?.setSheetCoordinator(nil)
                }
            }
            .store(in: &cancellables)

        parameters.navigationStackCoordinator?.setSheetCoordinator(coordinator) { [weak self] in
            self?.parameters.navigationStackCoordinator?.setSheetCoordinator(nil)
        }
    }
    
    private func presentNotificationSettings() {
        let notificationParameters = NotificationSettingsScreenCoordinatorParameters(navigationStackCoordinator: parameters.navigationStackCoordinator,
                                                                                     userSession: parameters.userSession,
                                                                                     userNotificationCenter: UNUserNotificationCenter.current(),
                                                                                     notificationSettings: parameters.notificationSettings,
                                                                                     isModallyPresented: false)
        let coordinator = NotificationSettingsScreenCoordinator(parameters: notificationParameters)
        parameters.navigationStackCoordinator?.push(coordinator)
    }
    
    private func presentAdvancedSettings() {
        let coordinator = AdvancedSettingsScreenCoordinator()
        parameters.navigationStackCoordinator?.push(coordinator)
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
        
        parameters.navigationStackCoordinator?.push(coordinator)
    }

    private func showSuccess(label: String) {
        parameters.userIndicatorController.submitIndicator(UserIndicator(title: label))
    }
}

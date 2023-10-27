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
import Foundation

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
    let appLockService: AppLockServiceProtocol
    let bugReportService: BugReportServiceProtocol
    let notificationSettings: NotificationSettingsProxyProtocol
    let secureBackupController: SecureBackupControllerProtocol
    let appSettings: AppSettings
    let navigationSplitCoordinator: NavigationSplitCoordinator
}

class SettingsFlowCoordinator: FlowCoordinatorProtocol {
    private let parameters: SettingsFlowCoordinatorParameters
    
    private var navigationStackCoordinator: NavigationStackCoordinator!
    private var userIndicatorController: UserIndicatorControllerProtocol!
    
    private var cancellables = Set<AnyCancellable>()
    
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
        
        userIndicatorController = UserIndicatorController(rootCoordinator: navigationStackCoordinator)
        
        let parameters = SettingsScreenCoordinatorParameters(navigationStackCoordinator: navigationStackCoordinator,
                                                             userIndicatorController: userIndicatorController,
                                                             userSession: parameters.userSession,
                                                             appLockService: parameters.appLockService,
                                                             bugReportService: parameters.bugReportService,
                                                             notificationSettings: parameters.userSession.clientProxy.notificationSettings,
                                                             secureBackupController: parameters.userSession.clientProxy.secureBackupController,
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
                case .clearCache:
                    actionsSubject.send(.clearCache)
                case .secureBackup:
                    presentSecureBackupScreen(animated: true)
                case .forceLogout:
                    actionsSubject.send(.forceLogout)
                }
            }
            .store(in: &cancellables)
        
        navigationStackCoordinator.setRootCoordinator(settingsScreenCoordinator, animated: animated)
        
        self.parameters.navigationSplitCoordinator.setSheetCoordinator(userIndicatorController) { [weak self] in
            guard let self else { return }
            
            navigationStackCoordinator = nil
            userIndicatorController = nil
            actionsSubject.send(.dismissedSettings)
        }
        
        actionsSubject.send(.presentedSettings)
    }
    
    private func presentSecureBackupScreen(animated: Bool) {
        let coordinator = SecureBackupScreenCoordinator(parameters: .init(appSettings: parameters.appSettings,
                                                                          secureBackupController: parameters.userSession.clientProxy.secureBackupController,
                                                                          navigationStackCoordinator: navigationStackCoordinator,
                                                                          userIndicatorController: userIndicatorController))
        
        navigationStackCoordinator.push(coordinator, animated: animated)
    }
}

//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

enum SettingsFlowCoordinatorAction {
    case dismiss
    case clearCache
    case runLogoutFlow
    /// Logout without a confirmation. The user forgot their PIN.
    case forceLogout
}

class SettingsFlowCoordinator: FlowCoordinatorProtocol {
    private let appLockService: AppLockServiceProtocol
    private let navigationStackCoordinator: NavigationStackCoordinator
    private let flowParameters: CommonFlowParameters
    
    // periphery:ignore - retaining purpose
    private var appLockSetupFlowCoordinator: AppLockSetupFlowCoordinator?
    // periphery:ignore - retaining purpose
    private var bugReportFlowCoordinator: BugReportFlowCoordinator?
    // periphery:ignore - retaining purpose
    private var encryptionSettingsFlowCoordinator: EncryptionSettingsFlowCoordinator?
    // periphery:ignore - retaining purpose
    private var linkNewDeviceFlowCoordinator: LinkNewDeviceFlowCoordinator?
    
    private var cancellables = Set<AnyCancellable>()
    
    private let actionsSubject: PassthroughSubject<SettingsFlowCoordinatorAction, Never> = .init()
    var actions: AnyPublisher<SettingsFlowCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(appLockService: AppLockServiceProtocol,
         navigationStackCoordinator: NavigationStackCoordinator,
         flowParameters: CommonFlowParameters) {
        self.appLockService = appLockService
        self.navigationStackCoordinator = navigationStackCoordinator
        self.flowParameters = flowParameters
    }
    
    func start(animated: Bool) {
        fatalError("Unavailable")
    }
    
    func handleAppRoute(_ appRoute: AppRoute, animated: Bool) {
        switch appRoute {
        case .settings:
            presentSettingsScreen(animated: animated)
        case .chatBackupSettings:
            startEncryptionSettingsFlow(animated: animated)
        default:
            break
        }
    }
    
    func clearRoute(animated: Bool) {
        fatalError("Unavailable")
    }
    
    // MARK: - Private
    
    private func presentSettingsScreen(animated: Bool) {
        let settingsScreenCoordinator = SettingsScreenCoordinator(parameters: .init(userSession: flowParameters.userSession,
                                                                                    appSettings: flowParameters.appSettings,
                                                                                    isBugReportServiceEnabled: flowParameters.bugReportService.isEnabled))
        
        settingsScreenCoordinator.actions
            .sink { [weak self] action in
                guard let self else { return }
                
                switch action {
                case .dismiss:
                    actionsSubject.send(.dismiss)
                case .logout:
                    actionsSubject.send(.runLogoutFlow)
                case .secureBackup:
                    startEncryptionSettingsFlow(animated: true)
                case .userDetails:
                    presentUserDetailsEditScreen()
                case .linkNewDevice:
                    startLinkNewDeviceFlow()
                case let .manageAccount(url):
                    presentAccountManagementURL(url)
                case .analytics:
                    presentAnalyticsScreen()
                case .appLock:
                    presentAppLockSetupFlow()
                case .bugReport:
                    bugReportFlowCoordinator = BugReportFlowCoordinator(parameters: .init(presentationMode: .push(navigationStackCoordinator),
                                                                                          userIndicatorController: flowParameters.userIndicatorController,
                                                                                          bugReportService: flowParameters.bugReportService,
                                                                                          userSession: flowParameters.userSession))
                    bugReportFlowCoordinator?.start()
                case .about:
                    presentLegalInformationScreen()
                case .blockedUsers:
                    presentBlockedUsersScreen()
                case .notifications:
                    presentNotificationSettings()
                case .advancedSettings:
                    presentAdvancedSettings()
                case .labs:
                    presentLabs()
                case .developerOptions:
                    presentDeveloperOptions()
                case .deactivateAccount:
                    presentDeactivateAccount()
                }
            }
            .store(in: &cancellables)
        
        navigationStackCoordinator.setRootCoordinator(settingsScreenCoordinator, animated: animated)
    }
    
    private func presentLabs() {
        let coordinator = LabsScreenCoordinator(parameters: .init(appSettings: flowParameters.appSettings))
        coordinator.actions
            .sink { [weak self] action in
                switch action {
                case .clearCache:
                    self?.actionsSubject.send(.clearCache)
                }
            }
            .store(in: &cancellables)
        
        navigationStackCoordinator.push(coordinator)
    }
    
    private func startEncryptionSettingsFlow(animated: Bool) {
        let coordinator = EncryptionSettingsFlowCoordinator(parameters: .init(userSession: flowParameters.userSession,
                                                                              appSettings: flowParameters.appSettings,
                                                                              userIndicatorController: flowParameters.userIndicatorController,
                                                                              navigationStackCoordinator: navigationStackCoordinator))
        coordinator.actionsPublisher.sink { [weak self] action in
            switch action {
            case .complete:
                // The flow coordinator tidies up the stack, no need to do anything.
                self?.encryptionSettingsFlowCoordinator = nil
            }
        }
        .store(in: &cancellables)
        
        encryptionSettingsFlowCoordinator = coordinator
        coordinator.start()
    }
    
    private func presentUserDetailsEditScreen() {
        let coordinator = UserDetailsEditScreenCoordinator(parameters: .init(orientationManager: flowParameters.windowManager,
                                                                             userSession: flowParameters.userSession,
                                                                             mediaUploadingPreprocessor: MediaUploadingPreprocessor(appSettings: flowParameters.appSettings),
                                                                             navigationStackCoordinator: navigationStackCoordinator,
                                                                             userIndicatorController: flowParameters.userIndicatorController,
                                                                             appSettings: flowParameters.appSettings))
        coordinator.actions
            .sink { [weak self] action in
                switch action {
                case .dismiss:
                    self?.navigationStackCoordinator.pop()
                }
            }
            .store(in: &cancellables)
        
        navigationStackCoordinator.push(coordinator)
    }
    
    private func startLinkNewDeviceFlow() {
        let stackCoordinator = NavigationStackCoordinator()
        let flowCoordinator = LinkNewDeviceFlowCoordinator(navigationStackCoordinator: stackCoordinator,
                                                           flowParameters: flowParameters)
        flowCoordinator.actionsPublisher
            .sink { [weak self] action in
                guard let self else { return }
                
                switch action {
                case .dismiss:
                    navigationStackCoordinator.setSheetCoordinator(nil)
                case .requestOIDCAuthorisation(let url, let continuation):
                    presentAccountManagementURL(url, continuation: continuation)
                }
            }
            .store(in: &cancellables)
        
        linkNewDeviceFlowCoordinator = flowCoordinator
        flowCoordinator.start()
        
        navigationStackCoordinator.setSheetCoordinator(stackCoordinator) { [weak self] in
            self?.linkNewDeviceFlowCoordinator = nil
        }
    }
    
    private func presentAnalyticsScreen() {
        let coordinator = AnalyticsSettingsScreenCoordinator(parameters: .init(appSettings: flowParameters.appSettings,
                                                                               analytics: flowParameters.analytics))
        navigationStackCoordinator.push(coordinator)
    }
    
    private func presentAppLockSetupFlow() {
        let coordinator = AppLockSetupFlowCoordinator(presentingFlow: .settings,
                                                      appLockService: appLockService,
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
        navigationStackCoordinator.push(LegalInformationScreenCoordinator(appSettings: flowParameters.appSettings))
    }
    
    private func presentBlockedUsersScreen() {
        let coordinator = BlockedUsersScreenCoordinator(parameters: .init(hideProfiles: flowParameters.appSettings.hideIgnoredUserProfiles,
                                                                          userSession: flowParameters.userSession,
                                                                          userIndicatorController: flowParameters.userIndicatorController))
        navigationStackCoordinator.push(coordinator)
    }
        
    private func presentNotificationSettings() {
        let notificationParameters = NotificationSettingsScreenCoordinatorParameters(navigationStackCoordinator: navigationStackCoordinator,
                                                                                     userSession: flowParameters.userSession,
                                                                                     userNotificationCenter: UNUserNotificationCenter.current(),
                                                                                     isModallyPresented: false,
                                                                                     appSettings: flowParameters.appSettings)
        let coordinator = NotificationSettingsScreenCoordinator(parameters: notificationParameters)
        navigationStackCoordinator.push(coordinator)
    }
    
    private func presentAdvancedSettings() {
        let coordinator = AdvancedSettingsScreenCoordinator(parameters: .init(appSettings: flowParameters.appSettings,
                                                                              analytics: flowParameters.analytics,
                                                                              clientProxy: flowParameters.userSession.clientProxy,
                                                                              userIndicatorController: flowParameters.userIndicatorController))
        navigationStackCoordinator.push(coordinator)
    }
    
    private func presentDeveloperOptions() {
        let coordinator = DeveloperOptionsScreenCoordinator(appSettings: flowParameters.appSettings,
                                                            appHooks: flowParameters.appHooks,
                                                            clientProxy: flowParameters.userSession.clientProxy)
        
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
        let parameters = DeactivateAccountScreenCoordinatorParameters(clientProxy: flowParameters.userSession.clientProxy,
                                                                      userIndicatorController: flowParameters.userIndicatorController)
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
    private func presentAccountManagementURL(_ url: URL, continuation: OIDCAccountSettingsPresenter.Continuation? = nil) {
        // Note to anyone in the future if you come back here to make this open in Safari instead of a WAS.
        // As of iOS 16, there is an issue on the simulator with accessing the cookie but it works on a device. 🤷‍♂️
        accountSettingsPresenter = OIDCAccountSettingsPresenter(accountURL: url,
                                                                presentationAnchor: flowParameters.windowManager.mainWindow,
                                                                appSettings: flowParameters.appSettings,
                                                                continuation: continuation)
        accountSettingsPresenter?.start()
    }
}

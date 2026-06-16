//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
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
    
    func start() {
        fatalError("Unavailable")
    }
    
    func handleAppRoute(_ appRoute: AppRoute, animated: Bool) {
        switch appRoute {
        case .settings:
            presentSettingsScreen(animated: animated)
        case .settingsTwoStepVerification:
            presentSettingsScreen(animated: animated)
            presentTwoStepVerification()
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
                case .developerOptions:
                    presentDeveloperOptions()
                case .deactivateAccount:
                    presentDeactivateAccount()
                case .twoStepVerification:
                    presentTwoStepVerification()
                case .findFriends:
                    presentFindFriends()
                }
            }
            .store(in: &cancellables)

        navigationStackCoordinator.setRootCoordinator(settingsScreenCoordinator, animated: animated)
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
        
        navigationStackCoordinator.push(coordinator)
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
        let coordinator = DeveloperOptionsScreenCoordinator(appSettings: flowParameters.appSettings)
        
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
        Task { @MainActor [weak self] in
            guard let self else { return }
            guard let url = await flowParameters.userSession.clientProxy.accountURL(action: .accountDeactivate) else {
                MXLog.error("MAS account deactivation URL unavailable.")
                flowParameters.userIndicatorController.submitIndicator(.init(title: L10n.errorUnknown))
                return
            }
            
            presentAccountManagementURL(url)
        }
    }

    // GUA FORK: Two-step verification entry-point.
    private func presentTwoStepVerification() {
        guard let identityServiceClient = IdentityServiceClient() else {
            MXLog.warning("Identity service is not configured; cannot show two-step verification screen.")
            return
        }
        let parameters = TwoStepVerificationScreenCoordinatorParameters(clientProxy: flowParameters.userSession.clientProxy,
                                                                        identityServiceClient: identityServiceClient,
                                                                        userIndicatorController: flowParameters.userIndicatorController)
        let coordinator = TwoStepVerificationScreenCoordinator(parameters: parameters)

        coordinator.actionsPublisher
            .sink { _ in }
            .store(in: &cancellables)

        navigationStackCoordinator.push(coordinator)
    }

    // GUA FORK: Find-friends-from-contacts entry-point.
    private func presentFindFriends() {
        guard let identityServiceClient = IdentityServiceClient() else {
            MXLog.warning("Identity service is not configured; cannot show Find Friends.")
            return
        }
        guard let accessToken = flowParameters.userSession.clientProxy.accessToken else {
            MXLog.warning("No access token available; cannot run contact discovery.")
            return
        }
        let contactDiscoveryService = ContactDiscoveryService(identityServiceClient: identityServiceClient)
        let parameters = FindFriendsScreenCoordinatorParameters(contactDiscoveryService: contactDiscoveryService,
                                                                clientProxy: flowParameters.userSession.clientProxy,
                                                                accessToken: accessToken)
        let coordinator = FindFriendsScreenCoordinator(parameters: parameters)

        coordinator.actionsPublisher
            .sink { [weak self] action in
                guard let self else { return }
                switch action {
                case .startedChat:
                    // The direct room now exists; close Settings so the user lands back on
                    // their chat list where the new conversation appears.
                    actionsSubject.send(.dismiss)
                case .showProfile(let userID):
                    presentFindFriendsUserProfile(userID: userID)
                case .close:
                    break
                }
            }
            .store(in: &cancellables)

        navigationStackCoordinator.push(coordinator)
    }

    private func presentFindFriendsUserProfile(userID: String) {
        let parameters = UserProfileScreenCoordinatorParameters(userID: userID,
                                                                isPresentedModally: false,
                                                                userSession: flowParameters.userSession,
                                                                userIndicatorController: flowParameters.userIndicatorController,
                                                                analytics: flowParameters.analytics)
        let coordinator = UserProfileScreenCoordinator(parameters: parameters)
        coordinator.actionsPublisher.sink { [weak self] action in
            guard let self else { return }
            switch action {
            case .openDirectChat:
                // Opening a chat from a contact's profile lands the user on their chat list.
                actionsSubject.send(.dismiss)
            case .startCall, .dismiss:
                navigationStackCoordinator.pop()
            }
        }
        .store(in: &cancellables)

        navigationStackCoordinator.push(coordinator)
    }

    private var accountSettingsPresenter: OIDCAccountSettingsPresenter?
    private func presentAccountManagementURL(_ url: URL) {
        // Note to anyone in the future if you come back here to make this open in Safari instead of a WAS.
        // As of iOS 16, there is an issue on the simulator with accessing the cookie but it works on a device. 🤷‍♂️
        accountSettingsPresenter = OIDCAccountSettingsPresenter(accountURL: url,
                                                                presentationAnchor: flowParameters.windowManager.mainWindow,
                                                                appSettings: flowParameters.appSettings)
        accountSettingsPresenter?.start()
    }
}

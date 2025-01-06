//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation
import SwiftState

enum EncryptionSettingsFlowCoordinatorAction: Equatable {
    /// The flow is complete.
    case complete
}

struct EncryptionSettingsFlowCoordinatorParameters {
    let userSession: UserSessionProtocol
    let appSettings: AppSettings
    let userIndicatorController: UserIndicatorControllerProtocol
    let navigationStackCoordinator: NavigationStackCoordinator
}

class EncryptionSettingsFlowCoordinator: FlowCoordinatorProtocol {
    private let userSession: UserSessionProtocol
    private let appSettings: AppSettings
    private let userIndicatorController: UserIndicatorControllerProtocol
    private let navigationStackCoordinator: NavigationStackCoordinator
    
    // periphery:ignore - retaining purpose
    private var encryptionResetFlowCoordinator: EncryptionResetFlowCoordinator?
    
    enum State: StateType {
        /// The state machine hasn't started.
        case initial
        /// The root screen for this flow.
        case secureBackupScreen
        /// The user is managing their recovery key.
        case recoveryKeyScreen
        /// The user is disabling key backups.
        case keyBackupScreen
    }
    
    enum Event: EventType {
        /// The flow is being started.
        case start
        
        /// The user would like to manage their recovery key.
        case manageRecoveryKey
        /// The user finished managing their recovery key.
        case finishedManagingRecoveryKey
        
        /// The user doesn't want to use key backup any more.
        case disableKeyBackup
        /// The key backup screen was dismissed.
        case finishedDisablingKeyBackup
    }
    
    private let stateMachine: StateMachine<State, Event>
    private var cancellables: Set<AnyCancellable> = []
    
    private let actionsSubject: PassthroughSubject<EncryptionSettingsFlowCoordinatorAction, Never> = .init()
    var actionsPublisher: AnyPublisher<EncryptionSettingsFlowCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: EncryptionSettingsFlowCoordinatorParameters) {
        userSession = parameters.userSession
        appSettings = parameters.appSettings
        userIndicatorController = parameters.userIndicatorController
        navigationStackCoordinator = parameters.navigationStackCoordinator
        
        stateMachine = .init(state: .initial)
        configureStateMachine()
    }
    
    func start() {
        stateMachine.tryEvent(.start)
    }
    
    func handleAppRoute(_ appRoute: AppRoute, animated: Bool) {
        switch appRoute {
        case .roomList, .room, .roomAlias, .childRoom, .childRoomAlias,
             .roomDetails, .roomMemberDetails, .userProfile,
             .event, .eventOnRoomAlias, .childEvent, .childEventOnRoomAlias,
             .call, .genericCallLink, .settings, .share:
            // These routes aren't in this flow so clear the entire stack.
            clearRoute(animated: animated)
        case .chatBackupSettings:
            popToRootScreen(animated: animated)
        }
    }
    
    func clearRoute(animated: Bool) {
        let fromState = stateMachine.state
        popToRootScreen(animated: animated)
        guard fromState != .initial else { return }
        navigationStackCoordinator.pop(animated: animated) // SecureBackup screen.
    }
    
    func popToRootScreen(animated: Bool) {
        // As we push screens on top of an existing stack, a literal pop to root wouldn't be safe.
        switch stateMachine.state {
        case .initial, .secureBackupScreen:
            break
        case .recoveryKeyScreen:
            navigationStackCoordinator.setSheetCoordinator(nil, animated: animated) // RecoveryKey screen.
        case .keyBackupScreen:
            navigationStackCoordinator.setSheetCoordinator(nil, animated: animated) // KeyBackup screen.
        }
    }
    
    // MARK: - Private
    
    private func configureStateMachine() {
        stateMachine.addRoutes(event: .start, transitions: [.initial => .secureBackupScreen]) { [weak self] _ in
            self?.presentSecureBackupScreen()
        }
        
        stateMachine.addRoutes(event: .manageRecoveryKey, transitions: [.secureBackupScreen => .recoveryKeyScreen]) { [weak self] _ in
            self?.presentRecoveryKeyScreen()
        }
        stateMachine.addRoutes(event: .finishedManagingRecoveryKey, transitions: [.recoveryKeyScreen => .secureBackupScreen])
        
        stateMachine.addRoutes(event: .disableKeyBackup, transitions: [.secureBackupScreen => .keyBackupScreen]) { [weak self] _ in
            self?.presentKeyBackupScreen()
        }
        stateMachine.addRoutes(event: .finishedDisablingKeyBackup, transitions: [.keyBackupScreen => .secureBackupScreen])
        
        stateMachine.addErrorHandler { context in
            fatalError("Unexpected transition: \(context)")
        }
    }
    
    private func presentSecureBackupScreen(animated: Bool = true) {
        let coordinator = SecureBackupScreenCoordinator(parameters: .init(appSettings: appSettings,
                                                                          clientProxy: userSession.clientProxy,
                                                                          userIndicatorController: userIndicatorController))
        coordinator.actions.sink { [weak self] action in
            guard let self else { return }
            
            switch action {
            case .manageRecoveryKey:
                stateMachine.tryEvent(.manageRecoveryKey)
            case .disableKeyBackup:
                stateMachine.tryEvent(.disableKeyBackup)
            }
        }
        .store(in: &cancellables)
        
        navigationStackCoordinator.push(coordinator, animated: animated) { [weak self] in
            self?.actionsSubject.send(.complete)
        }
    }
    
    private func presentRecoveryKeyScreen() {
        let sheetNavigationStackCoordinator = NavigationStackCoordinator()
        let coordinator = SecureBackupRecoveryKeyScreenCoordinator(parameters: .init(secureBackupController: userSession.clientProxy.secureBackupController,
                                                                                     userIndicatorController: userIndicatorController,
                                                                                     isModallyPresented: true))
        
        coordinator.actions.sink { [weak self] action in
            guard let self else { return }
            switch action {
            case .complete:
                navigationStackCoordinator.setSheetCoordinator(nil)
            }
        }
        .store(in: &cancellables)
        
        sheetNavigationStackCoordinator.setRootCoordinator(coordinator, animated: true)
        
        navigationStackCoordinator.setSheetCoordinator(sheetNavigationStackCoordinator) { [stateMachine] in
            stateMachine.tryEvent(.finishedManagingRecoveryKey)
        }
    }
    
    private func presentKeyBackupScreen() {
        let sheetNavigationStackCoordinator = NavigationStackCoordinator()
        
        let coordinator = SecureBackupKeyBackupScreenCoordinator(parameters: .init(secureBackupController: userSession.clientProxy.secureBackupController,
                                                                                   userIndicatorController: userIndicatorController))
        
        coordinator.actions.sink { [weak self] action in
            switch action {
            case .done:
                self?.navigationStackCoordinator.setSheetCoordinator(nil)
            }
        }
        .store(in: &cancellables)
        
        sheetNavigationStackCoordinator.setRootCoordinator(coordinator, animated: true)
        
        navigationStackCoordinator.setSheetCoordinator(sheetNavigationStackCoordinator) { [stateMachine] in
            stateMachine.tryEvent(.finishedDisablingKeyBackup)
        }
    }
}

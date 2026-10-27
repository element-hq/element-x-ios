//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftState

enum SecureBackupLogoutFlowCoordinatorAction {
    /// The user changed their mind about removing the device.
    case cancel
    /// The device can now be removed.
    case logout
}

struct SecureBackupLogoutFlowCoordinatorParameters {
    let userSession: UserSessionProtocol
    let userIndicatorController: UserIndicatorControllerProtocol
    let navigationStackCoordinator: NavigationStackCoordinator
    let mode: SecureBackupLogoutConfirmationScreenViewMode
}

/// Asks the user about the recovery key they'll need after removing their only verified device, and lets them create a new one.
class SecureBackupLogoutFlowCoordinator: FlowCoordinatorProtocol {
    private let userSession: UserSessionProtocol
    private let userIndicatorController: UserIndicatorControllerProtocol
    private let navigationStackCoordinator: NavigationStackCoordinator
    private let mode: SecureBackupLogoutConfirmationScreenViewMode
    
    enum State: StateType {
        /// The state machine hasn't started.
        case initial
        /// The root screen for this flow.
        case confirmationScreen
        /// Generating a new recovery key.
        case recoveryKeyScreen
    }
    
    enum Event: EventType {
        /// The flow is being started.
        case start
        
        /// The user wants to generate a new recovery key.
        case generateRecoveryKey
        /// The recovery key screen is no longer shown.
        case finishedRecoveryKey
    }
    
    private let stateMachine: StateMachine<State, Event>
    private var cancellables: Set<AnyCancellable> = []
    
    private let actionsSubject: PassthroughSubject<SecureBackupLogoutFlowCoordinatorAction, Never> = .init()
    var actionsPublisher: AnyPublisher<SecureBackupLogoutFlowCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: SecureBackupLogoutFlowCoordinatorParameters) {
        userSession = parameters.userSession
        userIndicatorController = parameters.userIndicatorController
        navigationStackCoordinator = parameters.navigationStackCoordinator
        mode = parameters.mode
        
        stateMachine = .init(state: .initial)
        configureStateMachine()
    }
    
    func start(animated: Bool) {
        stateMachine.tryEvent(.start)
    }
    
    func handleAppRoute(_ appRoute: AppRoute, animated: Bool) {
        // There aren't any routes to this flow, so always clear the stack.
        clearRoute(animated: animated)
    }
    
    func clearRoute(animated: Bool) {
        switch stateMachine.state {
        case .initial, .confirmationScreen:
            break
        case .recoveryKeyScreen:
            navigationStackCoordinator.popToRoot(animated: animated)
        }
    }
    
    // MARK: - Private
    
    private func configureStateMachine() {
        stateMachine.addRoutes(event: .start, transitions: [.initial => .confirmationScreen]) { [weak self] _ in
            self?.presentConfirmationScreen()
        }
        
        stateMachine.addRoutes(event: .generateRecoveryKey, transitions: [.confirmationScreen => .recoveryKeyScreen]) { [weak self] context in
            guard let continuation = context.userInfo as? SecureBackupLogoutConfirmationScreenRecoveryKeyContinuation else {
                fatalError("Expected a continuation in the userInfo.")
            }
            self?.presentRecoveryKeyScreen(continuation: continuation)
        }
        stateMachine.addRoutes(event: .finishedRecoveryKey, transitions: [.recoveryKeyScreen => .confirmationScreen])
        
        stateMachine.addErrorHandler { context in
            fatalError("Unexpected transition: \(context)")
        }
    }
    
    private func presentConfirmationScreen() {
        let coordinator = SecureBackupLogoutConfirmationScreenCoordinator(parameters: .init(secureBackupController: userSession.clientProxy.secureBackupController,
                                                                                            homeserverReachabilityPublisher: userSession.clientProxy.homeserverReachabilityPublisher,
                                                                                            learnMoreURL: userSession.userSettings.app.encryptionURL,
                                                                                            mode: mode))
        
        coordinator.actions
            .sink { [weak self] action in
                guard let self else { return }
                
                switch action {
                case .cancel:
                    actionsSubject.send(.cancel)
                case .generateRecoveryKey(let continuation):
                    stateMachine.tryEvent(.generateRecoveryKey, userInfo: continuation)
                case .logout:
                    actionsSubject.send(.logout)
                }
            }
            .store(in: &cancellables)
        
        navigationStackCoordinator.setRootCoordinator(coordinator)
    }
    
    private func presentRecoveryKeyScreen(continuation: SecureBackupLogoutConfirmationScreenRecoveryKeyContinuation) {
        let parameters = SecureBackupRecoveryKeyScreenCoordinatorParameters(secureBackupController: userSession.clientProxy.secureBackupController,
                                                                            userIndicatorController: userIndicatorController,
                                                                            isModallyPresented: false,
                                                                            presentationContext: .deviceRemoval)
        let coordinator = userSession.userHooks.recoveryKeyScreenHook.makeCoordinator(parameters: parameters)
        
        coordinator.actions
            .sink { [weak self] action in
                switch action {
                case .complete:
                    self?.navigationStackCoordinator.popToRoot(animated: true)
                    continuation.yield()
                }
            }
            .store(in: &cancellables)
        
        navigationStackCoordinator.push(coordinator) { [stateMachine] in
            // Leaving the screen without a new key ends the wait for one.
            continuation.finish()
            stateMachine.tryEvent(.finishedRecoveryKey)
        }
    }
}

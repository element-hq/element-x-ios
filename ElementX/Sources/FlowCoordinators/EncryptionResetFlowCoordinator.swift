//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation
import SwiftState

enum EncryptionResetFlowCoordinatorAction: Equatable {
    /// The flow is complete.
    case resetComplete
    /// The flow was cancelled.
    case cancel
}

struct EncryptionResetFlowCoordinatorParameters {
    let userSession: UserSessionProtocol
    let userIndicatorController: UserIndicatorControllerProtocol
    let navigationStackCoordinator: NavigationStackCoordinator
    let windowManger: WindowManagerProtocol
}

class EncryptionResetFlowCoordinator: FlowCoordinatorProtocol {
    private let userSession: UserSessionProtocol
    private let userIndicatorController: UserIndicatorControllerProtocol
    
    private let navigationStackCoordinator: NavigationStackCoordinator
    private let windowManager: WindowManagerProtocol
    
    enum State: StateType {
        /// The state machine hasn't started.
        case initial
        /// The root screen for this flow.
        case encryptionResetScreen
        /// Confirming the user's password to continue.
        case confirmingPassword
    }
    
    enum Event: EventType {
        /// The flow is being started.
        case start
        
        /// The user needs to confirm their password to reset.
        case confirmPassword
        /// The user confirmed their password.
        case finishedConfirmingPassword
    }
    
    private let stateMachine: StateMachine<State, Event>
    private var cancellables: Set<AnyCancellable> = []
    
    private let actionsSubject: PassthroughSubject<EncryptionResetFlowCoordinatorAction, Never> = .init()
    var actionsPublisher: AnyPublisher<EncryptionResetFlowCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: EncryptionResetFlowCoordinatorParameters) {
        userSession = parameters.userSession
        userIndicatorController = parameters.userIndicatorController
        navigationStackCoordinator = parameters.navigationStackCoordinator
        windowManager = parameters.windowManger
        
        stateMachine = .init(state: .initial)
        configureStateMachine()
    }
    
    func start() {
        stateMachine.tryEvent(.start)
    }
    
    func handleAppRoute(_ appRoute: AppRoute, animated: Bool) {
        // There aren't any routes to this screen, so always clear the stack.
        clearRoute(animated: animated)
    }
    
    func clearRoute(animated: Bool) {
        // As we push screens on top of an existing stack, popping to root wouldn't be safe.
        switch stateMachine.state {
        case .initial:
            break
        case .encryptionResetScreen:
            navigationStackCoordinator.pop(animated: animated)
        case .confirmingPassword:
            navigationStackCoordinator.pop(animated: animated) // Password screen.
            navigationStackCoordinator.pop(animated: animated) // EncryptionReset screen.
        }
    }
    
    // MARK: - Private
    
    private func configureStateMachine() {
        stateMachine.addRoutes(event: .start, transitions: [.initial => .encryptionResetScreen]) { [weak self] _ in
            self?.presentEncryptionResetScreen()
        }
        
        stateMachine.addRoutes(event: .confirmPassword, transitions: [.encryptionResetScreen => .confirmingPassword]) { [weak self] context in
            guard let passwordPublisher = context.userInfo as? PassthroughSubject<String, Never> else { fatalError("Expected a publisher in the userInfo.") }
            self?.presentPasswordScreen(passwordPublisher: passwordPublisher)
        }
        stateMachine.addRoutes(event: .finishedConfirmingPassword, transitions: [.confirmingPassword => .encryptionResetScreen])
        
        stateMachine.addErrorHandler { context in
            fatalError("Unexpected transition: \(context)")
        }
    }
    
    private func presentEncryptionResetScreen() {
        let coordinator = EncryptionResetScreenCoordinator(parameters: .init(clientProxy: userSession.clientProxy,
                                                                             userIndicatorController: userIndicatorController))
        
        coordinator.actionsPublisher.sink { [weak self] action in
            guard let self else { return }
            
            switch action {
            case .requestOIDCAuthorisation(let url):
                presentOIDCAuthorization(for: url)
            case .requestPassword(let passwordPublisher):
                stateMachine.tryEvent(.confirmPassword, userInfo: passwordPublisher)
            case .cancel:
                actionsSubject.send(.cancel)
            case .resetFinished:
                actionsSubject.send(.resetComplete)
            }
        }
        .store(in: &cancellables)
        
        navigationStackCoordinator.setRootCoordinator(coordinator)
    }
    
    private func presentPasswordScreen(passwordPublisher: PassthroughSubject<String, Never>) {
        let coordinator = EncryptionResetPasswordScreenCoordinator(parameters: .init(passwordPublisher: passwordPublisher))
        
        coordinator.actionsPublisher.sink { [weak self] action in
            guard let self else { return }
            
            switch action {
            case .passwordEntered:
                navigationStackCoordinator.pop()
            }
        }
        .store(in: &cancellables)
        
        navigationStackCoordinator.push(coordinator) { [stateMachine] in
            stateMachine.tryEvent(.finishedConfirmingPassword)
        }
    }
    
    private var accountSettingsPresenter: OIDCAccountSettingsPresenter?
    private func presentOIDCAuthorization(for url: URL) {
        // Note to anyone in the future if you come back here to make this open in Safari instead of a WAS.
        // As of iOS 16, there is an issue on the simulator with accessing the cookie but it works on a device. 🤷‍♂️
        accountSettingsPresenter = OIDCAccountSettingsPresenter(accountURL: url, presentationAnchor: windowManager.mainWindow)
        accountSettingsPresenter?.start()
    }
}

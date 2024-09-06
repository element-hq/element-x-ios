//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import SwiftState
import SwiftUI

enum AppLockSetupFlowCoordinatorAction: Equatable {
    /// The flow is complete.
    case complete
    /// The user failed to remember their existing PIN.
    case forceLogout
}

/// Coordinates the display of any screens used to configure the App Lock feature.
class AppLockSetupFlowCoordinator: FlowCoordinatorProtocol {
    private let presentingFlow: PresentationFlow
    private let appLockService: AppLockServiceProtocol
    private let navigationStackCoordinator: NavigationStackCoordinator
    private let modalNavigationStackCoordinator = NavigationStackCoordinator()
    
    /// The presentation context of the flow.
    enum PresentationFlow {
        /// The flow is shown for mandatory PIN creation in the authentication flow or on app launch.
        case onboarding
        /// The flow is shown from the Settings screen.
        case settings
    }
    
    /// States the flow can find itself in
    enum State: StateType {
        /// The initial state, used before the flow starts
        case initial
        /// The unlock screen.
        case unlock
        /// The create PIN screen.
        case createPIN(replacingExitingPIN: Bool)
        /// The allow biometrics screen.
        case biometricsPrompt
        /// The settings screen.
        case settings
        /// The flow is finished. This is a final state.
        case complete
        /// The user is being signed out. This is a final state.
        case loggingOut
    }

    /// Events that can be triggered on the flow state machine
    enum Event: EventType {
        /// Start the flow.
        case start
        /// The user entered a PIN.
        case pinEntered
        /// The user completed the biometrics prompt.
        case biometricsSet
        /// The user wants to change their PIN.
        case changePIN
        /// The user has disabled the app lock feature.
        case appLockDisabled
        /// The user wants to cancel the flow.
        case cancel
        /// The user failed to remember their existing PIN.
        case forceLogout
    }
    
    private let stateMachine: StateMachine<State, Event>
    private var cancellables: Set<AnyCancellable> = []
    
    private let actionsSubject: PassthroughSubject<AppLockSetupFlowCoordinatorAction, Never> = .init()
    var actions: AnyPublisher<AppLockSetupFlowCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(presentingFlow: PresentationFlow, appLockService: AppLockServiceProtocol, navigationStackCoordinator: NavigationStackCoordinator) {
        self.presentingFlow = presentingFlow
        self.appLockService = appLockService
        self.navigationStackCoordinator = navigationStackCoordinator
        
        stateMachine = .init(state: .initial)
        configureStateMachine()
    }
    
    func start() {
        stateMachine.tryEvent(.start)
    }
    
    func handleAppRoute(_ appRoute: AppRoute, animated: Bool) {
        // Deep links not supported.
    }
    
    func clearRoute(animated: Bool) {
        // Deep links not supported.
    }
    
    // MARK: - Private
    
    private func configureStateMachine() {
        stateMachine.addRouteMapping { [weak self] event, fromState, _ in
            guard let self else { return nil }
            
            switch (fromState, event) {
            case (.initial, .start):
                if presentingFlow == .onboarding { return .createPIN(replacingExitingPIN: false) }
                return appLockService.isEnabled ? .unlock : .createPIN(replacingExitingPIN: false)
            case (.unlock, .pinEntered):
                return .settings
            case (.unlock, .cancel):
                return .complete
            case (.unlock, .forceLogout):
                return .loggingOut
            case (.createPIN(let replacingExitingPIN), .pinEntered):
                if presentingFlow == .onboarding {
                    return appLockService.biometryType != .none ? .biometricsPrompt : .complete
                } else if !replacingExitingPIN {
                    return appLockService.biometricUnlockEnabled || appLockService.biometryType == .none ? .settings : .biometricsPrompt
                } else {
                    return .settings
                }
            case (.createPIN(let replacingExitingPIN), .cancel):
                return replacingExitingPIN ? .settings : .complete
            case (.biometricsPrompt, .biometricsSet):
                return presentingFlow == .settings ? .settings : .complete
            case (.settings, .changePIN):
                return .createPIN(replacingExitingPIN: true)
            case (.settings, .appLockDisabled):
                return .complete
            default:
                return nil
            }
        }
        
        stateMachine.addAnyHandler(.any => .any) { [weak self] context in
            guard let self else { return }
            
            MXLog.info("Transitioning from `\(context.fromState)` to `\(context.toState)` with event `\(String(describing: context.event))`.")
            switch (context.fromState, context.toState) {
            case (.initial, .unlock):
                showPINUnlock()
            case (.initial, .createPIN):
                showCreatePIN()
            case (.unlock, .settings):
                showSettings()
            case (.createPIN, .biometricsPrompt):
                showBiometricsPrompt()
            case (.createPIN(let replacingExitingPIN), .settings):
                if replacingExitingPIN {
                    navigationStackCoordinator.setSheetCoordinator(nil) // Reveal the settings screen again.
                } else {
                    showSettings() // Biometrics was unavailable, push the settings screen now.
                }
            case (.biometricsPrompt, .settings):
                showSettings()
            case (.settings, .createPIN):
                showCreatePIN()
            case (_, .complete):
                complete(from: context.fromState)
            case (.unlock, .loggingOut):
                actionsSubject.send(.forceLogout)
            default:
                fatalError("Unhandled transition.")
            }
        }
        
        stateMachine.addErrorHandler { context in
            fatalError("Unexpected transition from `\(context.fromState)` to `\(context.toState)` with event `\(String(describing: context.event))`.")
        }
    }

    private func showCreatePIN() {
        // Despite appLockService.isMandatory existing, we don't use that here,
        // to allow for cancellation when changing the PIN code within settings.
        let isMandatory = presentingFlow == .onboarding
        
        let coordinator = AppLockSetupPINScreenCoordinator(parameters: .init(initialMode: .create,
                                                                             isMandatory: isMandatory,
                                                                             appLockService: appLockService))
        coordinator.actions.sink { [weak self] action in
            guard let self else { return }
            switch action {
            case .complete:
                stateMachine.tryEvent(.pinEntered)
            case .cancel:
                stateMachine.tryEvent(.cancel)
            case .forceLogout:
                fatalError("Creating a PIN can't force a logout.")
            }
        }
        .store(in: &cancellables)
        
        if presentingFlow == .onboarding {
            if navigationStackCoordinator.rootCoordinator == nil {
                navigationStackCoordinator.setRootCoordinator(coordinator)
            } else {
                navigationStackCoordinator.push(coordinator)
            }
        } else {
            modalNavigationStackCoordinator.setRootCoordinator(coordinator)
            navigationStackCoordinator.setSheetCoordinator(modalNavigationStackCoordinator)
        }
    }
    
    private func showBiometricsPrompt() {
        let coordinator = AppLockSetupBiometricsScreenCoordinator(parameters: .init(appLockService: appLockService))
        coordinator.actions.sink { [weak self] action in
            guard let self else { return }
            switch action {
            case .continue:
                stateMachine.tryEvent(.biometricsSet)
            }
        }
        .store(in: &cancellables)
        
        if presentingFlow == .onboarding {
            navigationStackCoordinator.push(coordinator)
        } else {
            modalNavigationStackCoordinator.push(coordinator)
        }
    }
    
    private func showPINUnlock() {
        let coordinator = AppLockSetupPINScreenCoordinator(parameters: .init(initialMode: .unlock,
                                                                             isMandatory: false,
                                                                             appLockService: appLockService))
        coordinator.actions.sink { [weak self] action in
            guard let self else { return }
            switch action {
            case .complete:
                stateMachine.tryEvent(.pinEntered)
            case .cancel:
                stateMachine.tryEvent(.cancel)
            case .forceLogout:
                stateMachine.tryEvent(.forceLogout)
            }
        }
        .store(in: &cancellables)
        modalNavigationStackCoordinator.setRootCoordinator(coordinator)
        navigationStackCoordinator.setSheetCoordinator(modalNavigationStackCoordinator)
    }
    
    private func showSettings() {
        let coordinator = AppLockSetupSettingsScreenCoordinator(parameters: .init(appLockService: appLockService))
        coordinator.actions.sink { [weak self] action in
            guard let self else { return }
            switch action {
            case .changePINCode:
                stateMachine.tryEvent(.changePIN)
            case .appLockDisabled:
                stateMachine.tryEvent(.appLockDisabled)
            }
        }
        .store(in: &cancellables)
        
        navigationStackCoordinator.push(coordinator, animated: false) { [weak self] in
            self?.actionsSubject.send(.complete)
        }
        navigationStackCoordinator.setSheetCoordinator(nil)
    }
    
    /// Tear down the flow for completion.
    private func complete(from state: State) {
        switch state {
        case .initial, .complete, .loggingOut: fatalError()
        case .unlock:
            navigationStackCoordinator.setSheetCoordinator(nil)
            actionsSubject.send(.complete)
        case .createPIN:
            navigationStackCoordinator.setSheetCoordinator(nil)
            actionsSubject.send(.complete)
        case .biometricsPrompt:
            navigationStackCoordinator.setSheetCoordinator(nil)
            actionsSubject.send(.complete)
        case .settings:
            navigationStackCoordinator.pop()
            actionsSubject.send(.complete)
        }
    }
}

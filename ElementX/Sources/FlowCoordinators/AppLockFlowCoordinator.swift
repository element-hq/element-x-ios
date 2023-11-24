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
import SwiftState
import SwiftUI

enum AppLockFlowCoordinatorAction: Equatable {
    /// Display the unlock flow.
    case lockApp
    /// Hide the unlock flow.
    case unlockApp
    /// Forces a logout of the user.
    case forceLogout
}

/// Coordinates the display of any screens shown when the app is locked.
class AppLockFlowCoordinator: CoordinatorProtocol {
    let appLockService: AppLockServiceProtocol
    let navigationCoordinator: NavigationRootCoordinator
    
    /// States the flow can find itself in
    enum State: StateType {
        /// The initial state before the app has launched.
        case initial
        /// The app is in the foreground and visible to the user.
        case unlocked
        /// The app has resigned active but is not yet in the background. This state
        /// shows the placeholder, but doesn't require an unlock on becoming active.
        case obscuringApp
        /// The app is in the background.
        case backgrounded
        /// The app is presenting biometric unlock to the user.
        case biometricUnlock
        /// Biometric unlock has completed but the system UI is still the active input.
        /// Once the app becomes active again, it will trigger the next state.
        case biometricUnlockDismissing(AppLockServiceBiometricResult)
        /// The app is presenting the unlock screen for PIN code entry.
        case pinCodeUnlock
        /// The user failed to unlock the app (or forgot their PIN) and is being logged out.
        case loggingOut
    }

    /// Events that can be triggered on the flow state machine
    enum Event: EventType {
        /// The app is resigning active (going into the app switcher, showing system UI like Face ID, permissions prompt etc).
        case willResignActive
        /// The app is now backgrounded and not visible to the user.
        case didEnterBackground
        /// The app is in the foreground and has been given focus.
        case didBecomeActive
        /// Biometric unlock has completed with the following result.
        case biometricResult(AppLockServiceBiometricResult)
        /// The entered PIN code was accepted.
        case pinSuccess
        /// The user failed to unlock the app (or forgot their PIN).
        case forceLogout
        /// The service has been enabled.
        case serviceEnabled
        /// The service has been disabled.
        case serviceDisabled
    }
    
    private let stateMachine: StateMachine<State, Event>
    
    /// A task used to await biometric unlock before showing the PIN screen.
    @CancellableTask private var unlockTask: Task<Void, Never>?
    private var cancellables: Set<AnyCancellable> = []
    
    /// Whether or not biometric unlock should be attempted instead of asking for a PIN.
    private var biometricUnlockIsAvailable: Bool {
        appLockService.biometricUnlockEnabled && appLockService.biometricUnlockTrusted
    }
    
    private let actionsSubject: PassthroughSubject<AppLockFlowCoordinatorAction, Never> = .init()
    var actions: AnyPublisher<AppLockFlowCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(initialState: State = .initial,
         appLockService: AppLockServiceProtocol,
         navigationCoordinator: NavigationRootCoordinator,
         notificationCenter: NotificationCenter = .default) {
        self.appLockService = appLockService
        self.navigationCoordinator = navigationCoordinator
        
        // Set the initial state and start with the placeholder screen as the root view.
        stateMachine = .init(state: initialState)
        showPlaceholder()
        
        notificationCenter.publisher(for: UIApplication.willResignActiveNotification)
            .sink { [weak self] _ in
                self?.stateMachine.tryEvent(.willResignActive)
            }
            .store(in: &cancellables)
        
        notificationCenter.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                self?.stateMachine.tryEvent(.didEnterBackground)
            }
            .store(in: &cancellables)
        
        notificationCenter.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.stateMachine.tryEvent(.didBecomeActive)
            }
            .store(in: &cancellables)
        
        appLockService.isEnabledPublisher
            .sink { [weak self] isEnabled in
                self?.stateMachine.tryEvent(isEnabled ? .serviceEnabled : .serviceDisabled)
            }
            .store(in: &cancellables)
        
        configureStateMachine()
    }
    
    func toPresentable() -> AnyView {
        AnyView(navigationCoordinator.toPresentable())
    }
    
    // MARK: - State machine
    
    private func configureStateMachine() {
        stateMachine.addRouteMapping { [weak self] event, fromState, _ in
            guard let self, appLockService.isEnabled else { return fromState }
            
            switch (fromState, event) {
            case (.unlocked, .willResignActive):
                return .obscuringApp
            case (.obscuringApp, .didBecomeActive):
                return .unlocked
            case (_, .didEnterBackground):
                return .backgrounded
            case (.backgrounded, .didBecomeActive), (.initial, .didBecomeActive):
                guard appLockService.computeNeedsUnlock(didBecomeActiveAt: .now) else { return .unlocked }
                return biometricUnlockIsAvailable ? .biometricUnlock : .pinCodeUnlock
            case (.biometricUnlock, .biometricResult(let result)):
                return .biometricUnlockDismissing(result)
            case (.biometricUnlockDismissing(let result), .didBecomeActive):
                return switch result {
                case .unlocked: .unlocked
                case .failed: .pinCodeUnlock
                case .interrupted: .biometricUnlock
                }
            case (.pinCodeUnlock, .pinSuccess):
                return .unlocked
            case (.pinCodeUnlock, .forceLogout):
                return .loggingOut
            
            // Transition to a valid state when enabling the service for the first time.
            case (.initial, .serviceEnabled):
                return .unlocked
            // Transition to a valid state once the service is disabled following a forced logout.
            case (.loggingOut, .serviceDisabled):
                return .unlocked
            
            default:
                return fromState
            }
        }
        
        stateMachine.addAnyHandler(.any => .any) { [weak self] context in
            guard let self, context.fromState != context.toState else { return }
            
            MXLog.info("Transitioning from `\(context.fromState)` to `\(context.toState)` with event `\(String(describing: context.event))`.")
            
            switch (context.fromState, context.toState) {
            case (_, .obscuringApp):
                showPlaceholder()
            case (_, .backgrounded):
                appLockService.applicationDidEnterBackground()
                showPlaceholder() // Double call but just to be safe.
            case (_, .biometricUnlock):
                showPlaceholder() // For the unlock background. Triple call but just to be safe.
                Task { await self.attemptBiometricUnlock() }
            case (.biometricUnlock, .biometricUnlockDismissing):
                break // Transitional state, no need to do anything.
            case (_, .pinCodeUnlock):
                showUnlockScreen()
            case (_, .unlocked):
                actionsSubject.send(.unlockApp)
            case (_, .loggingOut):
                actionsSubject.send(.forceLogout)
            default:
                fatalError("Unhandled transition.")
            }
        }
        
        stateMachine.addErrorHandler { context in
            fatalError("Unexpected transition from `\(context.fromState)` to `\(context.toState)` with event `\(String(describing: context.event))`.")
        }
    }
    
    // MARK: - App unlock
    
    /// Displays the unlock flow with the app's placeholder view to hide obscure the view hierarchy in the app switcher.
    private func showPlaceholder() {
        navigationCoordinator.setRootCoordinator(PlaceholderScreenCoordinator(showsBackgroundGradient: true), animated: false)
        actionsSubject.send(.lockApp)
    }
    
    /// Attempts to authenticate the user using Face ID, Touch ID or (possibly) Optic ID.
    private func attemptBiometricUnlock() async {
        let result = await appLockService.unlockWithBiometrics()
        stateMachine.tryEvent(.biometricResult(result))
    }
    
    /// Displays the unlock flow with the main unlock screen.
    private func showUnlockScreen() {
        let coordinator = AppLockScreenCoordinator(parameters: .init(appLockService: appLockService))
        coordinator.actions.sink { [weak self] action in
            guard let self else { return }
            switch action {
            case .appUnlocked:
                stateMachine.tryEvent(.pinSuccess)
            case .forceLogout:
                stateMachine.tryEvent(.forceLogout)
            }
        }
        .store(in: &cancellables)
        
        navigationCoordinator.setRootCoordinator(coordinator, animated: false)
        actionsSubject.send(.lockApp)
    }
}

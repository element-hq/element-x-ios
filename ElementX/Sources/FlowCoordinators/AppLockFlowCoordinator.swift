//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
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
        /// The initial state before the app has launched. If the user hasn't enabled
        /// App Lock, then the flow will continue to remain in this state after launch.
        case initial
        /// The app is in the foreground and visible to the user.
        case unlocked
        /// The app has resigned active but is not yet in the background. This state
        /// shows the placeholder, but doesn't require an unlock on becoming active.
        case appObscured
        /// The app is in the background.
        case backgrounded
        /// The app is returning to the foreground.
        case launching
        /// The app is presenting biometric unlock to the user.
        case attemptingBiometricUnlock
        /// Biometric unlock has completed but the system UI is still the active input.
        /// Once the app becomes active again, it will trigger the next state.
        case dismissingBiometricUnlock(AppLockServiceBiometricResult)
        /// The app is presenting the unlock screen for PIN code entry.
        case attemptingPINUnlock
        /// The user failed to unlock the app (or forgot their PIN) and is being logged out.
        case loggingOut
    }

    /// Events that can be triggered on the flow state machine
    enum Event: EventType {
        /// Starts the flow while the app is launching in the background.
        case start
        /// The app is resigning active (going into the app switcher, showing system UI like Face ID, permissions prompt etc).
        case willResignActive
        /// The app is now backgrounded and not visible to the user.
        case didEnterBackground
        /// The app is in the background and has just been launched by the user.
        case willEnterForeground
        /// The app is in the foreground and has been given focus.
        case didBecomeActive
        /// Biometric unlock has completed with the following result.
        case didFinishBiometricUnlock(AppLockServiceBiometricResult)
        /// The entered PIN code was accepted.
        case didUnlockWithPIN
        /// The user failed to unlock the app (or forgot their PIN).
        case forceLogout
        /// The service has been enabled.
        case serviceEnabled
        /// The service has been disabled.
        case serviceDisabled
    }
    
    private let stateMachine: StateMachine<State, Event>
    
    private var cancellables: Set<AnyCancellable> = []
    
    /// Whether or not biometric unlock should be attempted instead of asking for a PIN.
    private var isBiometricUnlockAvailable: Bool {
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
        configureStateMachine()
        
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
        
        notificationCenter.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                self?.stateMachine.tryEvent(.willEnterForeground)
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
    }
    
    func toPresentable() -> AnyView {
        AnyView(navigationCoordinator.toPresentable())
    }
    
    // MARK: - State machine
    
    private func configureStateMachine() {
        stateMachine.addRouteMapping { [weak self] event, fromState, _ in
            guard let self, appLockService.isEnabled else { return fromState }
            
            switch (fromState, event) {
            case (.initial, .start):
                return .backgrounded
            
            case (.unlocked, .willResignActive):
                return .appObscured
            case (.appObscured, .didBecomeActive):
                return .unlocked
            case (_, .didEnterBackground):
                return .backgrounded
            case (_, .willEnterForeground):
                return .launching
            case (.launching, .didBecomeActive):
                guard appLockService.computeNeedsUnlock(didBecomeActiveAt: .now) else { return .unlocked }
                return isBiometricUnlockAvailable ? .attemptingBiometricUnlock : .attemptingPINUnlock
            case (.attemptingBiometricUnlock, .didFinishBiometricUnlock(let result)):
                return .dismissingBiometricUnlock(result) // Transitional state until the app becomes active again.
            case (.dismissingBiometricUnlock(let result), .didBecomeActive):
                return switch result {
                case .unlocked: .unlocked
                case .failed: .attemptingPINUnlock
                case .interrupted: .attemptingBiometricUnlock
                }
            case (.attemptingPINUnlock, .didUnlockWithPIN):
                return .unlocked
            case (.attemptingPINUnlock, .forceLogout):
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
            case (_, .appObscured):
                showPlaceholder()
            case (_, .backgrounded):
                appLockService.applicationDidEnterBackground()
                showPlaceholder() // Double call but just to be safe. Useful at app launch.
            case (_, .launching):
                showPlaceholder() // Triple call but necessary after being suspended.
            case (_, .attemptingBiometricUnlock):
                showPlaceholder() // For the unlock background. Quadruple call but just to be safe.
                Task { await self.attemptBiometricUnlock() }
            case (.attemptingBiometricUnlock, .dismissingBiometricUnlock):
                break // Transitional state, no need to do anything.
            case (_, .attemptingPINUnlock):
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
        
        stateMachine.tryEvent(.start)
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
        stateMachine.tryEvent(.didFinishBiometricUnlock(result))
    }
    
    /// Displays the unlock flow with the main unlock screen.
    private func showUnlockScreen() {
        let coordinator = AppLockScreenCoordinator(parameters: .init(appLockService: appLockService))
        coordinator.actions.sink { [weak self] action in
            guard let self else { return }
            switch action {
            case .appUnlocked:
                stateMachine.tryEvent(.didUnlockWithPIN)
            case .forceLogout:
                stateMachine.tryEvent(.forceLogout)
            }
        }
        .store(in: &cancellables)
        
        navigationCoordinator.setRootCoordinator(coordinator, animated: false)
        actionsSubject.send(.lockApp)
    }
}

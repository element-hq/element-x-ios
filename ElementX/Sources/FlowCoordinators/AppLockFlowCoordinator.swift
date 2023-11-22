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
    
    /// A task used to await biometric unlock before showing the PIN screen.
    @CancellableTask private var unlockTask: Task<Void, Never>?
    private var cancellables: Set<AnyCancellable> = []
    
    private let actionsSubject: PassthroughSubject<AppLockFlowCoordinatorAction, Never> = .init()
    var actions: AnyPublisher<AppLockFlowCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(appLockService: AppLockServiceProtocol,
         navigationCoordinator: NavigationRootCoordinator,
         notificationCenter: NotificationCenter = .default) {
        self.appLockService = appLockService
        self.navigationCoordinator = navigationCoordinator
        
        // Set the initial background state.
        showPlaceholder()
        
        notificationCenter.publisher(for: UIApplication.willResignActiveNotification)
            .sink { [weak self] _ in
                self?.applicationWillResignActive()
            }
            .store(in: &cancellables)
        
        notificationCenter.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                self?.applicationDidEnterBackground()
            }
            .store(in: &cancellables)
        
        notificationCenter.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.applicationDidBecomeActive()
            }
            .store(in: &cancellables)
    }
    
    func toPresentable() -> AnyView {
        AnyView(navigationCoordinator.toPresentable())
    }
    
    // MARK: - App unlock
    
    private func applicationWillResignActive() {
        unlockTask = nil
        
        guard appLockService.isEnabled else { return }
        showPlaceholder()
    }
    
    private func applicationDidEnterBackground() {
        guard appLockService.isEnabled else { return }
        appLockService.applicationDidEnterBackground()
        showPlaceholder() // Double call but just to be safe
    }
    
    private func applicationDidBecomeActive() {
        guard appLockService.isEnabled else { return }
        
        guard appLockService.computeNeedsUnlock(didBecomeActiveAt: .now) else {
            // Reveal the app again if within the grace period.
            actionsSubject.send(.unlockApp)
            return
        }
        
        // Show the relevant unlock mechanism.
        unlockTask = Task { [weak self] in
            guard let self else { return }
            await startUnlockFlow()
        }
    }
    
    /// Runs the unlock flow, showing Touch ID/Face ID if available, transitioning to PIN unlock if it fails or isn't available.
    private func startUnlockFlow() async {
        if appLockService.biometricUnlockEnabled, appLockService.biometricUnlockTrusted {
            showPlaceholder() // For the unlock background.
            
            if await appLockService.unlockWithBiometrics(), UIApplication.shared.applicationState == .active {
                actionsSubject.send(.unlockApp)
                return
            }
        }
        
        guard !Task.isCancelled else { return }
        
        showUnlockScreen()
    }
    
    /// Displays the unlock flow with the app's placeholder view to hide obscure the view hierarchy in the app switcher.
    private func showPlaceholder() {
        navigationCoordinator.setRootCoordinator(PlaceholderScreenCoordinator(showsBackgroundGradient: true), animated: false)
        actionsSubject.send(.lockApp)
    }
    
    /// Displays the unlock flow with the main unlock screen.
    private func showUnlockScreen() {
        let coordinator = AppLockScreenCoordinator(parameters: .init(appLockService: appLockService))
        coordinator.actions.sink { [weak self] action in
            guard let self else { return }
            switch action {
            case .appUnlocked:
                guard UIApplication.shared.applicationState == .active else { return }
                actionsSubject.send(.unlockApp)
            case .forceLogout:
                actionsSubject.send(.forceLogout)
            }
        }
        .store(in: &cancellables)
        
        navigationCoordinator.setRootCoordinator(coordinator, animated: false)
        actionsSubject.send(.lockApp)
    }
}

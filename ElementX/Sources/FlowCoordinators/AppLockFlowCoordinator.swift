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
    let userIndicatorController: UserIndicatorController
    let navigationCoordinator: NavigationRootCoordinator
    
    private var cancellables: Set<AnyCancellable> = []
    
    private let actionsSubject: PassthroughSubject<AppLockFlowCoordinatorAction, Never> = .init()
    var actions: AnyPublisher<AppLockFlowCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(appLockService: AppLockServiceProtocol, userIndicatorController: UserIndicatorController, navigationCoordinator: NavigationRootCoordinator) {
        self.appLockService = appLockService
        self.userIndicatorController = userIndicatorController
        self.navigationCoordinator = navigationCoordinator
        
        // Set the initial background state.
        showPlaceholder()
        
        appLockService.disabledPublisher
            .sink { [weak self] _ in
                // When the service is disabled via a force logout, we need to remove the activity indicator.
                self?.userIndicatorController.retractAllIndicators()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                self?.applicationDidEnterBackground()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                self?.applicationWillEnterForeground()
            }
            .store(in: &cancellables)
    }
    
    func toPresentable() -> AnyView {
        AnyView(userIndicatorController.toPresentable())
    }
    
    // MARK: - App unlock
    
    private func applicationDidEnterBackground() {
        guard appLockService.isEnabled else { return }
        
        appLockService.applicationDidEnterBackground()
        showPlaceholder()
    }
    
    private func applicationWillEnterForeground() {
        guard appLockService.isEnabled else { return }
        
        guard appLockService.computeNeedsUnlock(willEnterForegroundAt: .now) else {
            // Reveal the app again if within the grace period.
            actionsSubject.send(.unlockApp)
            return
        }
        
        Task { #warning("Handle bging and cancellation???")
            if appLockService.biometricUnlockEnabled, appLockService.biometricUnlockTrusted {
                showPlaceholder() // For the unlock background.
                
                if await appLockService.unlockWithBiometrics() {
                    actionsSubject.send(.unlockApp)
                    return
                }
            }
            
            guard !Task.isCancelled else { return }
            
            showUnlockScreen()
        }
    }
    
    /// Displays the unlock flow with the app's placeholder view to hide obscure the view hierarchy in the app switcher.
    private func showPlaceholder() {
        navigationCoordinator.setRootCoordinator(PlaceholderScreenCoordinator(), animated: false)
        actionsSubject.send(.lockApp)
    }
    
    /// Displays the unlock flow with the main unlock screen.
    private func showUnlockScreen() {
        let coordinator = AppLockScreenCoordinator(parameters: .init(appLockService: appLockService))
        coordinator.actions.sink { [weak self] action in
            guard let self else { return }
            switch action {
            case .appUnlocked:
                actionsSubject.send(.unlockApp)
            case .forceLogout:
                userIndicatorController.submitIndicator(UserIndicator(type: .modal, title: L10n.commonSigningOut, persistent: true))
                actionsSubject.send(.forceLogout)
            }
        }
        .store(in: &cancellables)
        
        navigationCoordinator.setRootCoordinator(coordinator, animated: false)
        actionsSubject.send(.lockApp)
    }
}

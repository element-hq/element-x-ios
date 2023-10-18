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
}

/// Coordinates the display of any screens shown when the app is locked.
class AppLockFlowCoordinator: CoordinatorProtocol {
    let appLockService: AppLockServiceProtocol
    let navigationCoordinator: NavigationRootCoordinator
    
    private var cancellables: Set<AnyCancellable> = []
    
    private let actionsSubject: PassthroughSubject<AppLockFlowCoordinatorAction, Never> = .init()
    var actions: AnyPublisher<AppLockFlowCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(appLockService: AppLockServiceProtocol, navigationCoordinator: NavigationRootCoordinator) {
        self.appLockService = appLockService
        self.navigationCoordinator = navigationCoordinator
        
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
        AnyView(navigationCoordinator.toPresentable())
    }
    
    // MARK: - App unlock
    
    private func applicationDidEnterBackground() {
        guard appLockService.isEnabled else { return }
        
        appLockService.applicationDidEnterBackground()
        showPlaceholder()
    }
    
    private func applicationWillEnterForeground() {
        guard appLockService.isEnabled, appLockService.computeNeedsUnlock(willEnterForegroundAt: .now) else { return }
        showUnlockScreen()
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
            }
        }
        .store(in: &cancellables)
        
        navigationCoordinator.setRootCoordinator(coordinator, animated: false)
        actionsSubject.send(.lockApp)
    }
}

//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import SwiftUI

struct AppLockScreenCoordinatorParameters {
    /// The service used to unlock the app.
    let appLockService: AppLockServiceProtocol
}

enum AppLockScreenCoordinatorAction {
    /// The user has successfully unlocked the app.
    case appUnlocked
    /// The user failed to unlock the app (or forgot their PIN).
    case forceLogout
}

final class AppLockScreenCoordinator: CoordinatorProtocol {
    private var viewModel: AppLockScreenViewModelProtocol
    private let actionsSubject: PassthroughSubject<AppLockScreenCoordinatorAction, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
    
    var actions: AnyPublisher<AppLockScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: AppLockScreenCoordinatorParameters) {
        viewModel = AppLockScreenViewModel(appLockService: parameters.appLockService)
    }
    
    func start() {
        viewModel.actions.sink { [weak self] action in
            MXLog.info("Coordinator: received view model action: \(action)")
            
            guard let self else { return }
            switch action {
            case .appUnlocked:
                self.actionsSubject.send(.appUnlocked)
            case .forceLogout:
                self.actionsSubject.send(.forceLogout)
            }
        }
        .store(in: &cancellables)
    }
        
    func toPresentable() -> AnyView {
        AnyView(AppLockScreen(context: viewModel.context))
    }
}

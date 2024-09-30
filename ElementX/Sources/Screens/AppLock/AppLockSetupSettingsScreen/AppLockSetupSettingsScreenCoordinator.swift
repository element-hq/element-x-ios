//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import SwiftUI

struct AppLockSetupSettingsScreenCoordinatorParameters {
    let appLockService: AppLockServiceProtocol
}

enum AppLockSetupSettingsScreenCoordinatorAction {
    case changePINCode
    case appLockDisabled
}

final class AppLockSetupSettingsScreenCoordinator: CoordinatorProtocol {
    private var viewModel: AppLockSetupSettingsScreenViewModelProtocol
    private let actionsSubject: PassthroughSubject<AppLockSetupSettingsScreenCoordinatorAction, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
    
    var actions: AnyPublisher<AppLockSetupSettingsScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: AppLockSetupSettingsScreenCoordinatorParameters) {
        viewModel = AppLockSetupSettingsScreenViewModel(appLockService: parameters.appLockService)
    }
    
    func start() {
        viewModel.actions.sink { [weak self] action in
            MXLog.info("Coordinator: received view model action: \(action)")
            
            guard let self else { return }
            switch action {
            case .changePINCode:
                actionsSubject.send(.changePINCode)
            case .appLockDisabled:
                actionsSubject.send(.appLockDisabled)
            }
        }
        .store(in: &cancellables)
    }
        
    func toPresentable() -> AnyView {
        AnyView(AppLockSetupSettingsScreen(context: viewModel.context))
    }
}

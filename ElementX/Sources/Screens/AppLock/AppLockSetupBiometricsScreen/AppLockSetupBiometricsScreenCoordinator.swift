//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import SwiftUI

struct AppLockSetupBiometricsScreenCoordinatorParameters {
    let appLockService: AppLockServiceProtocol
}

enum AppLockSetupBiometricsScreenCoordinatorAction {
    case `continue`
}

final class AppLockSetupBiometricsScreenCoordinator: CoordinatorProtocol {
    private var viewModel: AppLockSetupBiometricsScreenViewModelProtocol
    private let actionsSubject: PassthroughSubject<AppLockSetupBiometricsScreenCoordinatorAction, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
    
    var actions: AnyPublisher<AppLockSetupBiometricsScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: AppLockSetupBiometricsScreenCoordinatorParameters) {
        viewModel = AppLockSetupBiometricsScreenViewModel(appLockService: parameters.appLockService)
    }
    
    func start() {
        viewModel.actions.sink { [weak self] action in
            MXLog.info("Coordinator: received view model action: \(action)")
            
            guard let self else { return }
            switch action {
            case .continue:
                self.actionsSubject.send(.continue)
            }
        }
        .store(in: &cancellables)
    }
        
    func toPresentable() -> AnyView {
        AnyView(AppLockSetupBiometricsScreen(context: viewModel.context))
    }
}

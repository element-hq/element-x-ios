//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import SwiftUI

struct AppLockSetupPINScreenCoordinatorParameters {
    /// Whether the screen should start in create or unlock mode.
    /// Specifying confirm here will raise a fatal error.
    let initialMode: AppLockSetupPINScreenMode
    /// Whether the screen is mandatory or can be cancelled by the user.
    let isMandatory: Bool
    let appLockService: AppLockServiceProtocol
}

enum AppLockSetupPINScreenCoordinatorAction {
    /// The user succeeded PIN entry.
    case complete
    /// The user cancelled PIN entry.
    case cancel
    /// The user failed to remember their PIN to unlock.
    case forceLogout
}

final class AppLockSetupPINScreenCoordinator: CoordinatorProtocol {
    private var viewModel: AppLockSetupPINScreenViewModelProtocol
    private let actionsSubject: PassthroughSubject<AppLockSetupPINScreenCoordinatorAction, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
    
    var actions: AnyPublisher<AppLockSetupPINScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: AppLockSetupPINScreenCoordinatorParameters) {
        guard parameters.initialMode != .confirm else { fatalError(".confirm is an invalid initial mode") }
        
        viewModel = AppLockSetupPINScreenViewModel(initialMode: parameters.initialMode,
                                                   isMandatory: parameters.isMandatory,
                                                   appLockService: parameters.appLockService)
    }
    
    func start() {
        viewModel.actions.sink { [weak self] action in
            MXLog.info("Coordinator: received view model action: \(action)")
            
            guard let self else { return }
            switch action {
            case .complete:
                actionsSubject.send(.complete)
            case .cancel:
                actionsSubject.send(.cancel)
            case .forceLogout:
                actionsSubject.send(.forceLogout)
            }
        }
        .store(in: &cancellables)
    }
        
    func toPresentable() -> AnyView {
        AnyView(AppLockSetupPINScreen(context: viewModel.context))
    }
}

//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import SwiftUI

struct SecureBackupKeyBackupScreenCoordinatorParameters {
    let secureBackupController: SecureBackupControllerProtocol
    let userIndicatorController: UserIndicatorControllerProtocol
}

enum SecureBackupKeyBackupScreenCoordinatorAction {
    case done
}

final class SecureBackupKeyBackupScreenCoordinator: CoordinatorProtocol {
    private var viewModel: SecureBackupKeyBackupScreenViewModelProtocol
    private let actionsSubject: PassthroughSubject<SecureBackupKeyBackupScreenCoordinatorAction, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
    
    var actions: AnyPublisher<SecureBackupKeyBackupScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: SecureBackupKeyBackupScreenCoordinatorParameters) {
        viewModel = SecureBackupKeyBackupScreenViewModel(secureBackupController: parameters.secureBackupController,
                                                         userIndicatorController: parameters.userIndicatorController)
    }
    
    func start() {
        viewModel.actions.sink { [weak self] action in
            MXLog.info("Coordinator: received view model action: \(action)")
            
            guard let self else { return }
            switch action {
            case .done:
                self.actionsSubject.send(.done)
            }
        }
        .store(in: &cancellables)
    }
        
    func toPresentable() -> AnyView {
        AnyView(SecureBackupKeyBackupScreen(context: viewModel.context))
    }
}

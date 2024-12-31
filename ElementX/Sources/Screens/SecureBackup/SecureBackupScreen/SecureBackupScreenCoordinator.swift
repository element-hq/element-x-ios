//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

struct SecureBackupScreenCoordinatorParameters {
    let appSettings: AppSettings
    let clientProxy: ClientProxyProtocol
    let userIndicatorController: UserIndicatorControllerProtocol
}

enum SecureBackupScreenCoordinatorAction {
    case manageRecoveryKey
    case disableKeyBackup
}

final class SecureBackupScreenCoordinator: CoordinatorProtocol {
    private let parameters: SecureBackupScreenCoordinatorParameters
    private var viewModel: SecureBackupScreenViewModelProtocol
    
    private var cancellables = Set<AnyCancellable>()
    
    private let actionsSubject: PassthroughSubject<SecureBackupScreenCoordinatorAction, Never> = .init()
    var actions: AnyPublisher<SecureBackupScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: SecureBackupScreenCoordinatorParameters) {
        self.parameters = parameters
        
        viewModel = SecureBackupScreenViewModel(secureBackupController: parameters.clientProxy.secureBackupController,
                                                userIndicatorController: parameters.userIndicatorController,
                                                chatBackupDetailsURL: parameters.appSettings.chatBackupDetailsURL)
    }
    
    func start() {
        viewModel.actions.sink { [weak self] action in
            guard let self else { return }
            
            switch action {
            case .manageRecoveryKey:
                actionsSubject.send(.manageRecoveryKey)
            case .disableKeyBackup:
                actionsSubject.send(.disableKeyBackup)
            }
        }
        .store(in: &cancellables)
    }
    
    func toPresentable() -> AnyView {
        AnyView(SecureBackupScreen(context: viewModel.context))
    }
}

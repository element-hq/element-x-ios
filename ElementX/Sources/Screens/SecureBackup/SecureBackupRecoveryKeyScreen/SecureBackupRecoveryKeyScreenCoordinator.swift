//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

struct SecureBackupRecoveryKeyScreenCoordinatorParameters {
    let secureBackupController: SecureBackupControllerProtocol
    let userIndicatorController: UserIndicatorControllerProtocol
    let isModallyPresented: Bool
}

enum SecureBackupRecoveryKeyScreenCoordinatorAction {
    case complete
}

final class SecureBackupRecoveryKeyScreenCoordinator: CoordinatorProtocol {
    private let parameters: SecureBackupRecoveryKeyScreenCoordinatorParameters
    private var viewModel: SecureBackupRecoveryKeyScreenViewModelProtocol
    
    private var cancellables = Set<AnyCancellable>()
    
    private let actionsSubject: PassthroughSubject<SecureBackupRecoveryKeyScreenCoordinatorAction, Never> = .init()
    var actions: AnyPublisher<SecureBackupRecoveryKeyScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: SecureBackupRecoveryKeyScreenCoordinatorParameters) {
        self.parameters = parameters
        viewModel = SecureBackupRecoveryKeyScreenViewModel(secureBackupController: parameters.secureBackupController,
                                                           userIndicatorController: parameters.userIndicatorController,
                                                           isModallyPresented: parameters.isModallyPresented)
    }
    
    func start() {
        viewModel.actions.sink { [weak self] action in
            MXLog.info("Coordinator: received view model action: \(action)")
            
            guard let self else { return }
            switch action {
            case .cancel:
                self.actionsSubject.send(.complete)
            case .done(let mode):
                switch mode {
                case .setupRecovery:
                    showSuccessIndicator(title: L10n.screenRecoveryKeySetupSuccess)
                case .changeRecovery:
                    showSuccessIndicator(title: L10n.screenRecoveryKeyChangeSuccess)
                case .fixRecovery:
                    showSuccessIndicator(title: L10n.screenRecoveryKeyConfirmSuccess)
                case .unknown:
                    fatalError()
                }
                self.actionsSubject.send(.complete)
            }
        }
        .store(in: &cancellables)
    }
    
    func toPresentable() -> AnyView {
        AnyView(SecureBackupRecoveryKeyScreen(context: viewModel.context))
    }
    
    // MARK: - Private
    
    private func showSuccessIndicator(title: String) {
        parameters.userIndicatorController.submitIndicator(.init(id: .init(),
                                                                 type: .modal(progress: .none, interactiveDismissDisabled: false, allowsInteraction: false),
                                                                 title: title,
                                                                 iconName: "checkmark",
                                                                 persistent: false))
    }
}

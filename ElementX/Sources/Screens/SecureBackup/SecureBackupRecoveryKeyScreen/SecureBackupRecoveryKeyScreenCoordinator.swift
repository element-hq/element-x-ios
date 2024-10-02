//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import SwiftUI

struct SecureBackupRecoveryKeyScreenCoordinatorParameters {
    let secureBackupController: SecureBackupControllerProtocol
    let userIndicatorController: UserIndicatorControllerProtocol
    let isModallyPresented: Bool
}

enum SecureBackupRecoveryKeyScreenCoordinatorAction {
    case cancel
    case recoverySetUp
    case recoveryChanged
    case recoveryFixed
    case resetEncryption
}

final class SecureBackupRecoveryKeyScreenCoordinator: CoordinatorProtocol {
    private var viewModel: SecureBackupRecoveryKeyScreenViewModelProtocol
    private let actionsSubject: PassthroughSubject<SecureBackupRecoveryKeyScreenCoordinatorAction, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
    
    var actions: AnyPublisher<SecureBackupRecoveryKeyScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: SecureBackupRecoveryKeyScreenCoordinatorParameters) {
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
                self.actionsSubject.send(.cancel)
            case .done(let mode):
                switch mode {
                case .setupRecovery:
                    self.actionsSubject.send(.recoverySetUp)
                case .changeRecovery:
                    self.actionsSubject.send(.recoveryChanged)
                case .fixRecovery:
                    self.actionsSubject.send(.recoveryFixed)
                case .unknown:
                    fatalError()
                }
            case .resetEncryption:
                self.actionsSubject.send(.resetEncryption)
            }
        }
        .store(in: &cancellables)
    }
    
    func toPresentable() -> AnyView {
        AnyView(SecureBackupRecoveryKeyScreen(context: viewModel.context))
    }
}

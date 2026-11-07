//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

struct SecureBackupRecoveryKeyScreenCoordinatorParameters {
    let secureBackupController: SecureBackupControllerProtocol
    let userIndicatorController: UserIndicatorControllerProtocol
    let isModallyPresented: Bool
    var presentationContext = SecureBackupRecoveryKeyScreenPresentationContext.standard
}

enum SecureBackupRecoveryKeyScreenCoordinatorAction {
    case complete
}

final class SecureBackupRecoveryKeyScreenCoordinator: SecureBackupRecoveryKeyCoordinatorProtocol {
    private var viewModel: SecureBackupRecoveryKeyScreenViewModelProtocol
    
    private var cancellables = Set<AnyCancellable>()
    
    private let actionsSubject: PassthroughSubject<SecureBackupRecoveryKeyScreenCoordinatorAction, Never> = .init()
    var actions: AnyPublisher<SecureBackupRecoveryKeyScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: SecureBackupRecoveryKeyScreenCoordinatorParameters) {
        viewModel = SecureBackupRecoveryKeyScreenViewModel(secureBackupController: parameters.secureBackupController,
                                                           userIndicatorController: parameters.userIndicatorController,
                                                           isModallyPresented: parameters.isModallyPresented,
                                                           presentationContext: parameters.presentationContext)
    }
    
    func start() {
        viewModel.actions.sink { [weak self] action in
            MXLog.info("Coordinator: received view model action: \(action)")
            
            guard let self else { return }
            switch action {
            case .complete:
                self.actionsSubject.send(.complete)
            }
        }
        .store(in: &cancellables)
    }
    
    func toPresentable() -> AnyView {
        AnyView(SecureBackupRecoveryKeyScreen(context: viewModel.context))
    }
}

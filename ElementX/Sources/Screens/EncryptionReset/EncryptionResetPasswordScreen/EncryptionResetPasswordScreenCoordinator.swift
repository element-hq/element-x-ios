//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

struct EncryptionResetPasswordScreenCoordinatorParameters {
    let passwordPublisher: PassthroughSubject<String, Never>
}

enum EncryptionResetPasswordScreenCoordinatorAction {
    case passwordEntered
}

final class EncryptionResetPasswordScreenCoordinator: CoordinatorProtocol {
    private let parameters: EncryptionResetPasswordScreenCoordinatorParameters
    private let viewModel: EncryptionResetPasswordScreenViewModelProtocol
    
    private var cancellables = Set<AnyCancellable>()
 
    private let actionsSubject: PassthroughSubject<EncryptionResetPasswordScreenCoordinatorAction, Never> = .init()
    var actionsPublisher: AnyPublisher<EncryptionResetPasswordScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: EncryptionResetPasswordScreenCoordinatorParameters) {
        self.parameters = parameters
        
        viewModel = EncryptionResetPasswordScreenViewModel(passwordPublisher: parameters.passwordPublisher)
    }
    
    func start() {
        viewModel.actionsPublisher.sink { [weak self] action in
            MXLog.info("Coordinator: received view model action: \(action)")
            
            guard let self else { return }
            switch action {
            case .passwordEntered:
                self.actionsSubject.send(.passwordEntered)
            }
        }
        .store(in: &cancellables)
    }
        
    func toPresentable() -> AnyView {
        AnyView(EncryptionResetPasswordScreen(context: viewModel.context))
    }
}

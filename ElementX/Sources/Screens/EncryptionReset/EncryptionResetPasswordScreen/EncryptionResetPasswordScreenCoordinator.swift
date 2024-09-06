//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import SwiftUI

struct EncryptionResetPasswordScreenCoordinatorParameters { }

enum EncryptionResetPasswordScreenCoordinatorAction: CustomStringConvertible {
    case resetIdentity(String)
    
    var description: String {
        switch self {
        case .resetIdentity:
            "resetIdentity"
        }
    }
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
        
        viewModel = EncryptionResetPasswordScreenViewModel()
    }
    
    func start() {
        viewModel.actionsPublisher.sink { [weak self] action in
            MXLog.info("Coordinator: received view model action: \(action)")
            
            guard let self else { return }
            switch action {
            case .resetIdentity(let password):
                self.actionsSubject.send(.resetIdentity(password))
            }
        }
        .store(in: &cancellables)
    }
        
    func toPresentable() -> AnyView {
        AnyView(EncryptionResetPasswordScreen(context: viewModel.context))
    }
}

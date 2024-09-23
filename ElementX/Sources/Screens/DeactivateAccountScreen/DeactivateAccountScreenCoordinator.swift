//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import SwiftUI

struct DeactivateAccountScreenCoordinatorParameters {
    let clientProxy: ClientProxyProtocol
    let userIndicatorController: UserIndicatorControllerProtocol
}

enum DeactivateAccountScreenCoordinatorAction {
    case accountDeactivated
}

final class DeactivateAccountScreenCoordinator: CoordinatorProtocol {
    private let parameters: DeactivateAccountScreenCoordinatorParameters
    private let viewModel: DeactivateAccountScreenViewModelProtocol
    
    private var cancellables = Set<AnyCancellable>()
 
    private let actionsSubject: PassthroughSubject<DeactivateAccountScreenCoordinatorAction, Never> = .init()
    var actionsPublisher: AnyPublisher<DeactivateAccountScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: DeactivateAccountScreenCoordinatorParameters) {
        self.parameters = parameters
        
        viewModel = DeactivateAccountScreenViewModel(clientProxy: parameters.clientProxy,
                                                     userIndicatorController: parameters.userIndicatorController)
    }
    
    func start() {
        viewModel.actionsPublisher.sink { [weak self] action in
            MXLog.info("Coordinator: received view model action: \(action)")
            
            guard let self else { return }
            switch action {
            case .accountDeactivated:
                actionsSubject.send(.accountDeactivated)
            }
        }
        .store(in: &cancellables)
    }
        
    func toPresentable() -> AnyView {
        AnyView(DeactivateAccountScreen(context: viewModel.context))
    }
}

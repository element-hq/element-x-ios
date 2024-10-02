//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import SwiftUI

struct IdentityConfirmedScreenCoordinatorParameters { }

enum IdentityConfirmedScreenCoordinatorAction {
    case done
}

final class IdentityConfirmedScreenCoordinator: CoordinatorProtocol {
    private let parameters: IdentityConfirmedScreenCoordinatorParameters
    private let viewModel: IdentityConfirmedScreenViewModelProtocol
    
    private var cancellables = Set<AnyCancellable>()
 
    private let actionsSubject: PassthroughSubject<IdentityConfirmedScreenCoordinatorAction, Never> = .init()
    var actionsPublisher: AnyPublisher<IdentityConfirmedScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: IdentityConfirmedScreenCoordinatorParameters) {
        self.parameters = parameters
        
        viewModel = IdentityConfirmedScreenViewModel()
    }
    
    func start() {
        viewModel.actionsPublisher.sink { [weak self] action in
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
        AnyView(IdentityConfirmedScreen(context: viewModel.context))
    }
}

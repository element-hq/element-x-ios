//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

struct RemoteLogoutScreenCoordinatorParameters {
    let userSession: UserSessionProtocol
}

enum RemoteLogoutScreenCoordinatorAction {
    case done
}

final class RemoteLogoutScreenCoordinator: CoordinatorProtocol {
    private let parameters: RemoteLogoutScreenCoordinatorParameters
    private let viewModel: RemoteLogoutScreenViewModelProtocol
    
    private var cancellables = Set<AnyCancellable>()
    
    private let actionsSubject: PassthroughSubject<RemoteLogoutScreenCoordinatorAction, Never> = .init()
    var actionsPublisher: AnyPublisher<RemoteLogoutScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: RemoteLogoutScreenCoordinatorParameters) {
        self.parameters = parameters
        
        viewModel = RemoteLogoutScreenViewModel(userSession: parameters.userSession)
    }
    
    func start() {
        viewModel.actionsPublisher.sink { [weak self] action in
            MXLog.info("Coordinator: received view model action: \(action)")
            
            guard let self else { return }
            switch action {
            case .done:
                actionsSubject.send(.done)
            }
        }
        .store(in: &cancellables)
    }
    
    func toPresentable() -> AnyView {
        AnyView(RemoteLogoutScreen(context: viewModel.context))
    }
}

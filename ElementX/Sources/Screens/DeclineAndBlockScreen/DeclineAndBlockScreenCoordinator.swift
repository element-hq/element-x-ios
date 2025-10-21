//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

// periphery:ignore:all - this is just a reportInvite remove this comment once generating the final file

import Combine
import SwiftUI

struct DeclineAndBlockScreenCoordinatorParameters {
    let userID: String
    let roomID: String
    let clientProxy: ClientProxyProtocol
    let userIndicatorController: UserIndicatorControllerProtocol
}

enum DeclineAndBlockScreenCoordinatorAction {
    case dismiss(hasDeclined: Bool)
}

final class DeclineAndBlockScreenCoordinator: CoordinatorProtocol {
    private let parameters: DeclineAndBlockScreenCoordinatorParameters
    private let viewModel: DeclineAndBlockScreenViewModelProtocol
    
    private var cancellables = Set<AnyCancellable>()
 
    private let actionsSubject: PassthroughSubject<DeclineAndBlockScreenCoordinatorAction, Never> = .init()
    var actionsPublisher: AnyPublisher<DeclineAndBlockScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: DeclineAndBlockScreenCoordinatorParameters) {
        self.parameters = parameters
        
        viewModel = DeclineAndBlockScreenViewModel(userID: parameters.userID,
                                                   roomID: parameters.roomID,
                                                   clientProxy: parameters.clientProxy,
                                                   userIndicatorController: parameters.userIndicatorController)
    }
    
    func start() {
        viewModel.actionsPublisher.sink { [weak self] action in
            MXLog.info("Coordinator: received view model action: \(action)")
            
            guard let self else { return }
            switch action {
            case .dismiss(let hasDeclined):
                actionsSubject.send(.dismiss(hasDeclined: hasDeclined))
            }
        }
        .store(in: &cancellables)
    }
        
    func toPresentable() -> AnyView {
        AnyView(DeclineAndBlockScreen(context: viewModel.context))
    }
}

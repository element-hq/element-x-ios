//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

// periphery:ignore:all - this is just a spaceList remove this comment once generating the final file

import Combine
import SwiftUI

struct SpaceListScreenCoordinatorParameters {
    let userSession: UserSessionProtocol
}

enum SpaceListScreenCoordinatorAction {
    case showSettings
}

final class SpaceListScreenCoordinator: CoordinatorProtocol {
    private let parameters: SpaceListScreenCoordinatorParameters
    private let viewModel: SpaceListScreenViewModelProtocol
    
    private var cancellables = Set<AnyCancellable>()
 
    private let actionsSubject: PassthroughSubject<SpaceListScreenCoordinatorAction, Never> = .init()
    var actionsPublisher: AnyPublisher<SpaceListScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: SpaceListScreenCoordinatorParameters) {
        self.parameters = parameters
        
        viewModel = SpaceListScreenViewModel(userSession: parameters.userSession)
    }
    
    func start() {
        viewModel.actionsPublisher.sink { [weak self] action in
            MXLog.info("Coordinator: received view model action: \(action)")
            
            guard let self else { return }
            switch action {
            case .showSettings:
                actionsSubject.send(.showSettings)
            }
        }
        .store(in: &cancellables)
    }
        
    func toPresentable() -> AnyView {
        AnyView(SpaceListScreen(context: viewModel.context))
    }
}

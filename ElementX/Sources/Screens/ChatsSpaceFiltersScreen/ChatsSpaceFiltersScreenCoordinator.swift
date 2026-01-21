//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

// periphery:ignore:all - this is just a spaceFilter remove this comment once generating the final file

import Combine
import SwiftUI

struct ChatsSpaceFiltersScreenCoordinatorParameters {
    let spaceService: SpaceServiceProxyProtocol
    let mediaProvider: MediaProviderProtocol
}

enum ChatsSpaceFiltersScreenCoordinatorAction {
    case confirm(SpaceServiceFilter)
    case cancel
}

final class ChatsSpaceFiltersScreenCoordinator: CoordinatorProtocol {
    private let parameters: ChatsSpaceFiltersScreenCoordinatorParameters
    private let viewModel: ChatsSpaceFiltersScreenViewModelProtocol
    
    private var cancellables = Set<AnyCancellable>()
 
    private let actionsSubject: PassthroughSubject<ChatsSpaceFiltersScreenCoordinatorAction, Never> = .init()
    var actionsPublisher: AnyPublisher<ChatsSpaceFiltersScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: ChatsSpaceFiltersScreenCoordinatorParameters) {
        self.parameters = parameters
        
        viewModel = ChatsSpaceFiltersScreenViewModel(spaceService: parameters.spaceService,
                                                     mediaProvider: parameters.mediaProvider)
    }
    
    func start() {
        viewModel.actionsPublisher.sink { [weak self] action in
            MXLog.info("Coordinator: received view model action: \(action)")
            
            guard let self else { return }
            switch action {
            case .confirm(let spaceFilter):
                actionsSubject.send(.confirm(spaceFilter))
            case .cancel:
                actionsSubject.send(.cancel)
            }
        }
        .store(in: &cancellables)
    }
        
    func toPresentable() -> AnyView {
        AnyView(ChatsSpaceFiltersScreen(context: viewModel.context))
    }
}

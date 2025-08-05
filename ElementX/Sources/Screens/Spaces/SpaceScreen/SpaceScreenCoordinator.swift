//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

// periphery:ignore:all - this is just a space remove this comment once generating the final file

import Combine
import SwiftUI

struct SpaceScreenCoordinatorParameters {
    let spaceRoomListProxy: SpaceRoomListProxyProtocol
    let mediaProvider: MediaProviderProtocol
}

enum SpaceScreenCoordinatorAction {
    case selectSpace(SpaceRoomProxyProtocol)
}

final class SpaceScreenCoordinator: CoordinatorProtocol {
    private let parameters: SpaceScreenCoordinatorParameters
    private let viewModel: SpaceScreenViewModelProtocol
    
    private var cancellables = Set<AnyCancellable>()
 
    private let actionsSubject: PassthroughSubject<SpaceScreenCoordinatorAction, Never> = .init()
    var actionsPublisher: AnyPublisher<SpaceScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: SpaceScreenCoordinatorParameters) {
        self.parameters = parameters
        
        viewModel = SpaceScreenViewModel(spaceRoomList: parameters.spaceRoomListProxy, mediaProvider: parameters.mediaProvider)
    }
    
    func start() {
        viewModel.actionsPublisher.sink { [weak self] action in
            MXLog.info("Coordinator: received view model action: \(action)")
            
            guard let self else { return }
            switch action {
            case .selectSpace(let spaceRoom):
                actionsSubject.send(.selectSpace(spaceRoom))
            }
        }
        .store(in: &cancellables)
    }
        
    func toPresentable() -> AnyView {
        AnyView(SpaceScreen(context: viewModel.context))
    }
}

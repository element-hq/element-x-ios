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
    let spaceServiceProxy: SpaceServiceProxyProtocol
    let mediaProvider: MediaProviderProtocol
    let userIndicatorController: UserIndicatorControllerProtocol
}

enum SpaceScreenCoordinatorAction {
    case selectSpace(SpaceRoomListProxyProtocol)
    case selectRoom(roomID: String)
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
        
        viewModel = SpaceScreenViewModel(spaceRoomListProxy: parameters.spaceRoomListProxy,
                                         spaceServiceProxy: parameters.spaceServiceProxy,
                                         mediaProvider: parameters.mediaProvider,
                                         userIndicatorController: parameters.userIndicatorController)
    }
    
    func start() {
        viewModel.actionsPublisher.sink { [weak self] action in
            MXLog.info("Coordinator: received view model action: \(action)")
            
            guard let self else { return }
            switch action {
            case .selectSpace(let spaceRoomListProxy):
                actionsSubject.send(.selectSpace(spaceRoomListProxy))
            case .selectRoom(let roomID):
                actionsSubject.send(.selectRoom(roomID: roomID))
            }
        }
        .store(in: &cancellables)
    }
        
    func toPresentable() -> AnyView {
        AnyView(SpaceScreen(context: viewModel.context))
    }
}

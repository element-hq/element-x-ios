//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import SwiftUI

struct RoomDirectorySearchScreenCoordinatorParameters {
    let clientProxy: ClientProxyProtocol
    let mediaProvider: MediaProviderProtocol
    let userIndicatorController: UserIndicatorControllerProtocol
}

enum RoomDirectorySearchScreenCoordinatorAction {
    case selectAlias(String)
    case selectRoomID(String)
    case dismiss
}

final class RoomDirectorySearchScreenCoordinator: CoordinatorProtocol {
    private let viewModel: RoomDirectorySearchScreenViewModelProtocol
    
    private var cancellables = Set<AnyCancellable>()
    
    private let actionsSubject: PassthroughSubject<RoomDirectorySearchScreenCoordinatorAction, Never> = .init()
    var actionsPublisher: AnyPublisher<RoomDirectorySearchScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: RoomDirectorySearchScreenCoordinatorParameters) {
        viewModel = RoomDirectorySearchScreenViewModel(clientProxy: parameters.clientProxy,
                                                       userIndicatorController: parameters.userIndicatorController,
                                                       mediaProvider: parameters.mediaProvider)
    }
    
    func start() {
        viewModel.actionsPublisher.sink { [weak self] action in
            guard let self else { return }
            switch action {
            case .selectAlias(let alias):
                actionsSubject.send(.selectAlias(alias))
            case .selectRoomID(let roomID):
                actionsSubject.send(.selectRoomID(roomID))
            case .dismiss:
                actionsSubject.send(.dismiss)
            }
        }
        .store(in: &cancellables)
    }
        
    func toPresentable() -> AnyView {
        AnyView(RoomDirectorySearchScreen(context: viewModel.context))
    }
}

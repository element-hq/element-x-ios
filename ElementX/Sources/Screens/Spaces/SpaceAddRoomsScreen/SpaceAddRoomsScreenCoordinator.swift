//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

struct SpaceAddRoomsScreenCoordinatorParameters {
    let spaceRoomListProxy: SpaceRoomListProxyProtocol
    let userSession: UserSessionProtocol
    let roomSummaryProvider: RoomSummaryProviderProtocol
    let userIndicatorController: UserIndicatorControllerProtocol
}

enum SpaceAddRoomsScreenCoordinatorAction {
    case dismiss
}

final class SpaceAddRoomsScreenCoordinator: CoordinatorProtocol {
    private var viewModel: SpaceAddRoomsScreenViewModelProtocol
    private let actionsSubject: PassthroughSubject<SpaceAddRoomsScreenCoordinatorAction, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
    
    var actions: AnyPublisher<SpaceAddRoomsScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: SpaceAddRoomsScreenCoordinatorParameters) {
        viewModel = SpaceAddRoomsScreenViewModel(spaceRoomListProxy: parameters.spaceRoomListProxy,
                                                 userSession: parameters.userSession,
                                                 roomSummaryProvider: parameters.roomSummaryProvider,
                                                 userIndicatorController: parameters.userIndicatorController)
    }
    
    func start() {
        viewModel.actions.sink { [weak self] action in
            switch action {
            case .dismiss:
                self?.actionsSubject.send(.dismiss)
            }
        }
        .store(in: &cancellables)
    }
        
    func toPresentable() -> AnyView {
        AnyView(SpaceAddRoomsScreen(context: viewModel.context))
    }
    
    func stop() {
        viewModel.stop()
    }
}

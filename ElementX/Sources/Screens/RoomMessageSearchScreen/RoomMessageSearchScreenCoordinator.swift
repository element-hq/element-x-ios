//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

struct RoomMessageSearchScreenCoordinatorParameters {
    let roomProxy: JoinedRoomProxyProtocol
    let mediaProvider: MediaProviderProtocol
}

enum RoomMessageSearchScreenCoordinatorAction {
    case dismiss
    case displayEvent(eventID: String)
}

final class RoomMessageSearchScreenCoordinator: CoordinatorProtocol {
    private let parameters: RoomMessageSearchScreenCoordinatorParameters
    private let viewModel: RoomMessageSearchScreenViewModelProtocol

    private var cancellables = Set<AnyCancellable>()

    private let actionsSubject: PassthroughSubject<RoomMessageSearchScreenCoordinatorAction, Never> = .init()
    var actionsPublisher: AnyPublisher<RoomMessageSearchScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(parameters: RoomMessageSearchScreenCoordinatorParameters) {
        self.parameters = parameters

        viewModel = RoomMessageSearchScreenViewModel(roomProxy: parameters.roomProxy,
                                                     mediaProvider: parameters.mediaProvider)
    }

    func start() {
        viewModel.actionsPublisher.sink { [weak self] action in
            guard let self else { return }
            switch action {
            case .dismiss:
                actionsSubject.send(.dismiss)
            case .displayEvent(let eventID):
                actionsSubject.send(.displayEvent(eventID: eventID))
            }
        }
        .store(in: &cancellables)
    }

    func toPresentable() -> AnyView {
        AnyView(RoomMessageSearchScreen(context: viewModel.context))
    }
}

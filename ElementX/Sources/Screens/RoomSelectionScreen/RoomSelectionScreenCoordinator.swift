//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

struct RoomSelectionScreenCoordinatorParameters {
    let clientProxy: ClientProxyProtocol
    let roomSummaryProvider: RoomSummaryProviderProtocol
    let mediaProvider: MediaProviderProtocol
}

enum RoomSelectionScreenCoordinatorAction {
    case dismiss
    case confirm(roomID: String)
}

final class RoomSelectionScreenCoordinator: CoordinatorProtocol {
    private var viewModel: RoomSelectionScreenViewModelProtocol
    private let actionsSubject: PassthroughSubject<RoomSelectionScreenCoordinatorAction, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
    
    var actionsPublisher: AnyPublisher<RoomSelectionScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: RoomSelectionScreenCoordinatorParameters) {
        viewModel = RoomSelectionScreenViewModel(clientProxy: parameters.clientProxy,
                                                 roomSummaryProvider: parameters.roomSummaryProvider,
                                                 mediaProvider: parameters.mediaProvider)
    }
    
    func start() {
        viewModel.actionsPublisher.sink { [weak self] action in
            switch action {
            case .dismiss:
                self?.actionsSubject.send(.dismiss)
            case .confirm(let roomID):
                self?.actionsSubject.send(.confirm(roomID: roomID))
            }
        }
        .store(in: &cancellables)
    }
        
    func toPresentable() -> AnyView {
        AnyView(RoomSelectionScreen(context: viewModel.context))
    }
}

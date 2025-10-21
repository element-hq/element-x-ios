//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

struct MessageForwardingScreenCoordinatorParameters {
    let forwardingItem: MessageForwardingItem
    let userSession: UserSessionProtocol
    let roomSummaryProvider: RoomSummaryProviderProtocol
    let userIndicatorController: UserIndicatorControllerProtocol
}

enum MessageForwardingScreenCoordinatorAction {
    case dismiss
    case sent(roomID: String)
}

final class MessageForwardingScreenCoordinator: CoordinatorProtocol {
    private var viewModel: MessageForwardingScreenViewModelProtocol
    private let actionsSubject: PassthroughSubject<MessageForwardingScreenCoordinatorAction, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
    
    var actions: AnyPublisher<MessageForwardingScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: MessageForwardingScreenCoordinatorParameters) {
        viewModel = MessageForwardingScreenViewModel(forwardingItem: parameters.forwardingItem,
                                                     userSession: parameters.userSession,
                                                     roomSummaryProvider: parameters.roomSummaryProvider,
                                                     userIndicatorController: parameters.userIndicatorController)
    }
    
    func start() {
        viewModel.actions.sink { [weak self] action in
            switch action {
            case .dismiss:
                self?.actionsSubject.send(.dismiss)
            case .sent(let roomID):
                self?.actionsSubject.send(.sent(roomID: roomID))
            }
        }
        .store(in: &cancellables)
    }
        
    func toPresentable() -> AnyView {
        AnyView(MessageForwardingScreen(context: viewModel.context))
    }
    
    func stop() {
        viewModel.stop()
    }
}

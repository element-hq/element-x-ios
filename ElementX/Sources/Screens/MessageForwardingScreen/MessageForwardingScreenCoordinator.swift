//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import SwiftUI

struct MessageForwardingScreenCoordinatorParameters {
    let forwardingItem: MessageForwardingItem
    let clientProxy: ClientProxyProtocol
    let roomSummaryProvider: RoomSummaryProviderProtocol
    let mediaProvider: MediaProviderProtocol
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
                                                     clientProxy: parameters.clientProxy,
                                                     roomSummaryProvider: parameters.roomSummaryProvider,
                                                     userIndicatorController: parameters.userIndicatorController,
                                                     mediaProvider: parameters.mediaProvider)
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
}

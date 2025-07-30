//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

struct MessageSearchCoordinatorParameters {
    let roomProxy: JoinedRoomProxyProtocol
}

enum MessageSearchCoordinatorAction {
    case selectMessage(eventID: String)
    case dismiss
}

final class MessageSearchCoordinator: CoordinatorProtocol {
    private let parameters: MessageSearchCoordinatorParameters
    private let viewModel: MessageSearchViewModel
    
    private let actionsSubject: PassthroughSubject<MessageSearchCoordinatorAction, Never> = .init()
    var actionsPublisher: AnyPublisher<MessageSearchCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: MessageSearchCoordinatorParameters) {
        self.parameters = parameters
        viewModel = MessageSearchViewModel(roomProxy: parameters.roomProxy)
        
        viewModel.actionsPublisher
            .sink { [weak self] (action: MessageSearchViewModelAction) in
                guard let self else { return }
                
                switch action {
                case .selectMessage(let eventID):
                    actionsSubject.send(.selectMessage(eventID: eventID))
                case .dismiss:
                    actionsSubject.send(.dismiss)
                }
            }
            .store(in: &cancellables)
    }
    
    func start() {
        viewModel.start()
    }
    
    func stop() {
        viewModel.stop()
    }
    
    func toPresentable() -> AnyView {
        AnyView(MessageSearchScreen(context: viewModel.context))
    }
    
    private var cancellables = Set<AnyCancellable>()
}

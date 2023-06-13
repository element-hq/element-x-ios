//
// Copyright 2022 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Combine
import SwiftUI

struct MessageForwardingScreenCoordinatorParameters {
    let roomSummaryProvider: RoomSummaryProviderProtocol
}

enum MessageForwardingScreenCoordinatorAction {
    case dismiss
    case send(roomID: String)
}

final class MessageForwardingScreenCoordinator: CoordinatorProtocol {
    private let parameters: MessageForwardingScreenCoordinatorParameters
    private var viewModel: MessageForwardingScreenViewModelProtocol
    private let actionsSubject: PassthroughSubject<MessageForwardingScreenCoordinatorAction, Never> = .init()
    private var cancellables: Set<AnyCancellable> = .init()
    
    var actions: AnyPublisher<MessageForwardingScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: MessageForwardingScreenCoordinatorParameters) {
        self.parameters = parameters
        
        viewModel = MessageForwardingScreenViewModel(roomSummaryProvider: parameters.roomSummaryProvider)
    }
    
    func start() {
        viewModel.actions.sink { [weak self] action in
            switch action {
            case .dismiss:
                self?.actionsSubject.send(.dismiss)
            case .send(let roomID):
                self?.actionsSubject.send(.send(roomID: roomID))
            }
        }
        .store(in: &cancellables)
    }
        
    func toPresentable() -> AnyView {
        AnyView(MessageForwardingScreen(context: viewModel.context))
    }
}

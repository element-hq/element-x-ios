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
    let forwardingItem: MessageForwardingItem
    let clientProxy: ClientProxyProtocol
    let roomSummaryProvider: RoomSummaryProviderProtocol
    let mediaProvider: MediaProviderProtocol
    let networkMonitor: NetworkMonitorProtocol
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
                                                     mediaProvider: parameters.mediaProvider,
                                                     networkMonitor: parameters.networkMonitor)
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

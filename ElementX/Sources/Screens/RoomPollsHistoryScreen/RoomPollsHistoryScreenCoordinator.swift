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

struct RoomPollsHistoryScreenCoordinatorParameters {
    let pollInteractionHandler: PollInteractionHandlerProtocol
    let roomTimelineController: RoomTimelineControllerProtocol
}

enum RoomPollsHistoryScreenCoordinatorAction {
    case editPoll(pollStartID: String, poll: Poll)
}

final class RoomPollsHistoryScreenCoordinator: CoordinatorProtocol {
    private var viewModel: RoomPollsHistoryScreenViewModelProtocol
    private let actionsSubject: PassthroughSubject<RoomPollsHistoryScreenCoordinatorAction, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
    
    var actions: AnyPublisher<RoomPollsHistoryScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: RoomPollsHistoryScreenCoordinatorParameters) {
        viewModel = RoomPollsHistoryScreenViewModel(pollInteractionHandler: parameters.pollInteractionHandler,
                                                    roomTimelineController: parameters.roomTimelineController,
                                                    userIndicatorController: ServiceLocator.shared.userIndicatorController)
    }
    
    func start() {
        viewModel.actions.sink { [weak self] action in
            guard let self else { return }
            switch action {
            case .editPoll(let pollStartID, let poll):
                actionsSubject.send(.editPoll(pollStartID: pollStartID, poll: poll))
            }
        }
        .store(in: &cancellables)
    }
        
    func toPresentable() -> AnyView {
        AnyView(RoomPollsHistoryScreen(context: viewModel.context))
    }
}

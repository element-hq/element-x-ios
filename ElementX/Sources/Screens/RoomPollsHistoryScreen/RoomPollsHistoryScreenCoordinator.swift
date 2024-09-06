//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
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

//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import SwiftUI

struct RoomMemberDetailsScreenCoordinatorParameters {
    let userID: String
    let roomProxy: JoinedRoomProxyProtocol
    let clientProxy: ClientProxyProtocol
    let mediaProvider: MediaProviderProtocol
    let userIndicatorController: UserIndicatorControllerProtocol
    let analytics: AnalyticsService
}

enum RoomMemberDetailsScreenCoordinatorAction {
    case openUserProfile
    case openDirectChat(roomID: String)
    case startCall(roomID: String)
}

final class RoomMemberDetailsScreenCoordinator: CoordinatorProtocol {
    private var viewModel: RoomMemberDetailsScreenViewModelProtocol

    private let actionsSubject: PassthroughSubject<RoomMemberDetailsScreenCoordinatorAction, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
    
    var actions: AnyPublisher<RoomMemberDetailsScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(parameters: RoomMemberDetailsScreenCoordinatorParameters) {
        viewModel = RoomMemberDetailsScreenViewModel(userID: parameters.userID,
                                                     roomProxy: parameters.roomProxy,
                                                     clientProxy: parameters.clientProxy,
                                                     mediaProvider: parameters.mediaProvider,
                                                     userIndicatorController: parameters.userIndicatorController,
                                                     analytics: parameters.analytics)
    }
    
    func start() {
        viewModel.actions.sink { [weak self] action in
            guard let self else { return }
            
            switch action {
            case .openUserProfile:
                actionsSubject.send(.openUserProfile)
            case .openDirectChat(let roomID):
                actionsSubject.send(.openDirectChat(roomID: roomID))
            case .startCall(let roomID):
                actionsSubject.send(.startCall(roomID: roomID))
            }
        }
        .store(in: &cancellables)
    }
    
    func stop() {
        viewModel.stop()
    }

    func toPresentable() -> AnyView {
        AnyView(RoomMemberDetailsScreen(context: viewModel.context))
    }
}

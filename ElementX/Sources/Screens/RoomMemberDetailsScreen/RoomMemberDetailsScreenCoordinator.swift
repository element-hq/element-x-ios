//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

struct RoomMemberDetailsScreenCoordinatorParameters {
    let userID: String
    let roomProxy: JoinedRoomProxyProtocol
    let userSession: UserSessionProtocol
    let userIndicatorController: UserIndicatorControllerProtocol
    let analytics: AnalyticsService
}

enum RoomMemberDetailsScreenCoordinatorAction {
    case openUserProfile
    case openDirectChat(roomID: String)
    case startCall(roomProxy: JoinedRoomProxyProtocol)
    case verifyUser(userID: String)
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
                                                     userSession: parameters.userSession,
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
            case .startCall(let roomProxy):
                actionsSubject.send(.startCall(roomProxy: roomProxy))
            case .verifyUser(let userID):
                actionsSubject.send(.verifyUser(userID: userID))
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

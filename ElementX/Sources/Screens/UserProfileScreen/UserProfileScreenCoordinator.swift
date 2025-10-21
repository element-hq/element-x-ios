//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

struct UserProfileScreenCoordinatorParameters {
    let userID: String
    let isPresentedModally: Bool
    let userSession: UserSessionProtocol
    let userIndicatorController: UserIndicatorControllerProtocol
    let analytics: AnalyticsService
}

enum UserProfileScreenCoordinatorAction {
    case openDirectChat(roomID: String)
    case startCall(roomProxy: JoinedRoomProxyProtocol)
    case dismiss
}

final class UserProfileScreenCoordinator: CoordinatorProtocol {
    private var viewModel: UserProfileScreenViewModelProtocol
    
    private var cancellables = Set<AnyCancellable>()
    
    private let actionsSubject: PassthroughSubject<UserProfileScreenCoordinatorAction, Never> = .init()
    var actionsPublisher: AnyPublisher<UserProfileScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: UserProfileScreenCoordinatorParameters) {
        viewModel = UserProfileScreenViewModel(userID: parameters.userID,
                                               isPresentedModally: parameters.isPresentedModally,
                                               userSession: parameters.userSession,
                                               userIndicatorController: parameters.userIndicatorController,
                                               analytics: parameters.analytics)
    }
    
    func start() {
        viewModel.actionsPublisher.sink { [weak self] action in
            guard let self else { return }
            
            switch action {
            case .openDirectChat(let roomID):
                actionsSubject.send(.openDirectChat(roomID: roomID))
            case .startCall(let roomProxy):
                actionsSubject.send(.startCall(roomProxy: roomProxy))
            case .dismiss:
                actionsSubject.send(.dismiss)
            }
        }
        .store(in: &cancellables)
    }
    
    func stop() {
        viewModel.stop()
    }
    
    func toPresentable() -> AnyView {
        AnyView(UserProfileScreen(context: viewModel.context))
    }
}

//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import SwiftUI

struct UserProfileScreenCoordinatorParameters {
    let userID: String
    let isPresentedModally: Bool
    let clientProxy: ClientProxyProtocol
    let mediaProvider: MediaProviderProtocol
    let userIndicatorController: UserIndicatorControllerProtocol
    let analytics: AnalyticsService
}

enum UserProfileScreenCoordinatorAction {
    case openDirectChat(roomID: String)
    case startCall(roomID: String)
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
                                               clientProxy: parameters.clientProxy,
                                               mediaProvider: parameters.mediaProvider,
                                               userIndicatorController: parameters.userIndicatorController,
                                               analytics: parameters.analytics)
    }
    
    func start() {
        viewModel.actionsPublisher.sink { [weak self] action in
            guard let self else { return }
            
            switch action {
            case .openDirectChat(let roomID):
                actionsSubject.send(.openDirectChat(roomID: roomID))
            case .startCall(let roomID):
                actionsSubject.send(.startCall(roomID: roomID))
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

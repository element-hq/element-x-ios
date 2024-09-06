//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import SwiftUI

struct JoinRoomScreenCoordinatorParameters {
    let roomID: String
    let via: [String]
    let clientProxy: ClientProxyProtocol
    let mediaProvider: MediaProviderProtocol
    let userIndicatorController: UserIndicatorControllerProtocol
}

enum JoinRoomScreenCoordinatorAction {
    case joined
    case cancelled
}

final class JoinRoomScreenCoordinator: CoordinatorProtocol {
    private let viewModel: JoinRoomScreenViewModelProtocol
    
    private var cancellables = Set<AnyCancellable>()
 
    private let actionsSubject: PassthroughSubject<JoinRoomScreenCoordinatorAction, Never> = .init()
    var actionsPublisher: AnyPublisher<JoinRoomScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: JoinRoomScreenCoordinatorParameters) {
        viewModel = JoinRoomScreenViewModel(roomID: parameters.roomID,
                                            via: parameters.via,
                                            clientProxy: parameters.clientProxy,
                                            mediaProvider: parameters.mediaProvider,
                                            userIndicatorController: parameters.userIndicatorController)
    }
    
    func start() {
        viewModel.actionsPublisher.sink { [weak self] action in
            MXLog.info("Coordinator: received view model action: \(action)")
            
            guard let self else { return }
            switch action {
            case .joined:
                actionsSubject.send(.joined)
            case .cancelled:
                actionsSubject.send(.cancelled)
            }
        }
        .store(in: &cancellables)
    }
    
    func stop() {
        viewModel.stop()
    }
        
    func toPresentable() -> AnyView {
        AnyView(JoinRoomScreen(context: viewModel.context))
    }
}

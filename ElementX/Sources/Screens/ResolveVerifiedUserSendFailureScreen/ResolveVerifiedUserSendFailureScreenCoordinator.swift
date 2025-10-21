//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

struct ResolveVerifiedUserSendFailureScreenCoordinatorParameters {
    let failure: TimelineItemSendFailure.VerifiedUser
    let sendHandle: SendHandleProxy
    let roomProxy: JoinedRoomProxyProtocol
    let userIndicatorController: UserIndicatorControllerProtocol
}

enum ResolveVerifiedUserSendFailureScreenCoordinatorAction {
    case dismiss
}

final class ResolveVerifiedUserSendFailureScreenCoordinator: CoordinatorProtocol {
    private let parameters: ResolveVerifiedUserSendFailureScreenCoordinatorParameters
    private let viewModel: ResolveVerifiedUserSendFailureScreenViewModelProtocol
    
    private var cancellables = Set<AnyCancellable>()
 
    private let actionsSubject: PassthroughSubject<ResolveVerifiedUserSendFailureScreenCoordinatorAction, Never> = .init()
    var actionsPublisher: AnyPublisher<ResolveVerifiedUserSendFailureScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: ResolveVerifiedUserSendFailureScreenCoordinatorParameters) {
        self.parameters = parameters
        
        viewModel = ResolveVerifiedUserSendFailureScreenViewModel(failure: parameters.failure,
                                                                  sendHandle: parameters.sendHandle,
                                                                  roomProxy: parameters.roomProxy,
                                                                  userIndicatorController: parameters.userIndicatorController)
    }
    
    func start() {
        viewModel.actionsPublisher.sink { [weak self] action in
            MXLog.info("Coordinator: received view model action: \(action)")
            
            guard let self else { return }
            switch action {
            case .dismiss:
                actionsSubject.send(.dismiss)
            }
        }
        .store(in: &cancellables)
    }
        
    func toPresentable() -> AnyView {
        AnyView(ResolveVerifiedUserSendFailureScreen(context: viewModel.context))
    }
}

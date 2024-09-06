//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import SwiftUI

enum SessionVerificationScreenCoordinatorAction {
    case done
}

struct SessionVerificationScreenCoordinatorParameters {
    let sessionVerificationControllerProxy: SessionVerificationControllerProxyProtocol
}

final class SessionVerificationScreenCoordinator: CoordinatorProtocol {
    private var viewModel: SessionVerificationScreenViewModelProtocol
    
    private let actionsSubject: PassthroughSubject<SessionVerificationScreenCoordinatorAction, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
    
    var actions: AnyPublisher<SessionVerificationScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: SessionVerificationScreenCoordinatorParameters) {
        viewModel = SessionVerificationScreenViewModel(sessionVerificationControllerProxy: parameters.sessionVerificationControllerProxy)
    }
    
    // MARK: - Public
    
    func start() {
        viewModel.actions
            .sink { [weak self] action in
                guard let self else { return }
                
                switch action {
                case .finished:
                    actionsSubject.send(.done)
                }
            }
            .store(in: &cancellables)
    }
    
    func stop() {
        viewModel.stop()
    }
    
    func toPresentable() -> AnyView {
        AnyView(SessionVerificationScreen(context: viewModel.context))
    }
}

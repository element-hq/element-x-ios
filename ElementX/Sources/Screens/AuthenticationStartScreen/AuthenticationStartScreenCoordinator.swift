//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import SwiftUI

final class AuthenticationStartScreenCoordinator: CoordinatorProtocol {
    private var viewModel: AuthenticationStartScreenViewModelProtocol
    private let actionsSubject: PassthroughSubject<AuthenticationStartScreenCoordinatorAction, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
    
    var actions: AnyPublisher<AuthenticationStartScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init() {
        viewModel = AuthenticationStartScreenViewModel()
    }
    
    // MARK: - Public
    
    func start() {
        viewModel.actions
            .sink { [weak self] action in
                guard let self else { return }
                
                switch action {
                case .loginManually:
                    actionsSubject.send(.loginManually)
                case .loginWithQR:
                    actionsSubject.send(.loginWithQR)
                case .reportProblem:
                    actionsSubject.send(.reportProblem)
                }
            }
            .store(in: &cancellables)
    }
    
    func toPresentable() -> AnyView {
        AnyView(AuthenticationStartScreen(context: viewModel.context))
    }
}

//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import SwiftUI

struct CreateAccountScreenParameters {
    let authenticationService: AuthenticationServiceProtocol
    let userIndicatorController: UserIndicatorControllerProtocol
    let inviteCode: String
}

final class CreateAccountScreenCoordinator: CoordinatorProtocol {
    private var viewModel: CreateAccountScreenViewModelProtocol
        
    private let actionsSubject: PassthroughSubject<CreateAccountScreenCoordinatorAction, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
    
    var actions: AnyPublisher<CreateAccountScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: CreateAccountScreenParameters) {
        viewModel = CreateAccountScreenViewModel(authenticationService: parameters.authenticationService,
                                                 userIndicatorController: parameters.userIndicatorController,
                                                 inviteCode: parameters.inviteCode)
    }
    
    // MARK: - Public
    
    func start() {
        viewModel.actions
            .sink { [weak self] action in
                guard let self else { return }
                
                switch action {
                case .accountCreated(let session):
                    actionsSubject.send(.accountCreated(userSession: session))
                case .openLoginScreen:
                    actionsSubject.send(.openLoginScreen)
                }
            }
            .store(in: &cancellables)
    }
    
    func toPresentable() -> AnyView {
        AnyView(CreateAccountScreen(context: viewModel.context))
    }
}

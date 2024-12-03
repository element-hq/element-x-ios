//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import SwiftUI

struct CompleteProfileScreenParameters {
    let authenticationService: AuthenticationServiceProtocol
    let userIndicatorController: UserIndicatorControllerProtocol
    let inviteCode: String
}

final class CompleteProfileScreenCoordinator: CoordinatorProtocol {
    private var viewModel: CompleteProfileScreenViewModelProtocol
        
    private let actionsSubject: PassthroughSubject<CompleteProfileScreenCoordinatorAction, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
    
    var actions: AnyPublisher<CompleteProfileScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: CompleteProfileScreenParameters) {
        viewModel = CompleteProfileScreenViewModel(authenticationService: parameters.authenticationService,
                                                 userIndicatorController: parameters.userIndicatorController,
                                                 inviteCode: parameters.inviteCode)
    }
    
    // MARK: - Public
    
    func start() {
        viewModel.actions
            .sink { [weak self] action in
                guard let self else { return }
                
//                switch action {
//                case .accountCreated:
//                    actionsSubject.send(.accountCreated)
//                case .openLoginScreen:
//                    actionsSubject.send(.openLoginScreen)
//                }
            }
            .store(in: &cancellables)
    }
    
    func toPresentable() -> AnyView {
        AnyView(CompleteProfileScreen(context: viewModel.context))
    }
}

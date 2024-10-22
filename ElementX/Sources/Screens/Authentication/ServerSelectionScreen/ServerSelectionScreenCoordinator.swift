//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

struct ServerSelectionScreenCoordinatorParameters {
    /// The service used to authenticate the user.
    let authenticationService: AuthenticationServiceProtocol
    let authenticationFlow: AuthenticationFlow
    let slidingSyncLearnMoreURL: URL
    let userIndicatorController: UserIndicatorControllerProtocol
}

enum ServerSelectionScreenCoordinatorAction {
    case updated
    case dismiss
}

// Note: This code was brought over from Riot, we should move the authentication service logic into the view model.
final class ServerSelectionScreenCoordinator: CoordinatorProtocol {
    private let parameters: ServerSelectionScreenCoordinatorParameters
    private let userIndicatorController: UserIndicatorControllerProtocol
    private var viewModel: ServerSelectionScreenViewModelProtocol
    private var authenticationService: AuthenticationServiceProtocol { parameters.authenticationService }

    private let actionsSubject: PassthroughSubject<ServerSelectionScreenCoordinatorAction, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
    
    var actions: AnyPublisher<ServerSelectionScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: ServerSelectionScreenCoordinatorParameters) {
        self.parameters = parameters
        viewModel = ServerSelectionScreenViewModel(authenticationService: parameters.authenticationService,
                                                   authenticationFlow: parameters.authenticationFlow,
                                                   slidingSyncLearnMoreURL: parameters.slidingSyncLearnMoreURL,
                                                   userIndicatorController: parameters.userIndicatorController)
        userIndicatorController = parameters.userIndicatorController
    }
    
    // MARK: - Public
    
    func start() {
        viewModel.actions
            .sink { [weak self] action in
                guard let self else { return }
                
                switch action {
                case .updated:
                    actionsSubject.send(.updated)
                case .dismiss:
                    actionsSubject.send(.dismiss)
                }
            }
            .store(in: &cancellables)
    }
    
    func stop() {
        parameters.userIndicatorController.retractAllIndicators()
    }
    
    func toPresentable() -> AnyView {
        AnyView(ServerSelectionScreen(context: viewModel.context))
    }
}

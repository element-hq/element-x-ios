//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

// periphery:ignore:all - this is just a classicAppAccountConfirmation remove this comment once generating the final file

import Combine
import SwiftUI

struct ClassicAppAccountConfirmationScreenCoordinatorParameters {
    let classicAppAccount: ClassicAppAccount
    let authenticationService: AuthenticationServiceProtocol
    let userIndicatorController: UserIndicatorControllerProtocol
}

enum ClassicAppAccountConfirmationScreenCoordinatorAction {
    case loginDirectlyWithOIDC(data: OIDCAuthorizationDataProxy, window: UIWindow)
    case loginDirectlyWithPassword(loginHint: String)
}

final class ClassicAppAccountConfirmationScreenCoordinator: CoordinatorProtocol {
    private let parameters: ClassicAppAccountConfirmationScreenCoordinatorParameters
    private let viewModel: ClassicAppAccountConfirmationScreenViewModelProtocol
    
    private var cancellables = Set<AnyCancellable>()
 
    private let actionsSubject: PassthroughSubject<ClassicAppAccountConfirmationScreenCoordinatorAction, Never> = .init()
    var actionsPublisher: AnyPublisher<ClassicAppAccountConfirmationScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: ClassicAppAccountConfirmationScreenCoordinatorParameters) {
        self.parameters = parameters
        
        viewModel = ClassicAppAccountConfirmationScreenViewModel(classicAppAccount: parameters.classicAppAccount,
                                                                 authenticationService: parameters.authenticationService,
                                                                 userIndicatorController: parameters.userIndicatorController)
    }
    
    func start() {
        viewModel.actionsPublisher.sink { [weak self] action in
            MXLog.info("Coordinator: received view model action: \(action)")
            
            guard let self else { return }
            switch action {
            case .loginDirectlyWithOIDC(let data, let window):
                actionsSubject.send(.loginDirectlyWithOIDC(data: data, window: window))
            case .loginDirectlyWithPassword(let loginHint):
                actionsSubject.send(.loginDirectlyWithPassword(loginHint: loginHint))
            }
        }
        .store(in: &cancellables)
    }
        
    func toPresentable() -> AnyView {
        AnyView(ClassicAppAccountConfirmationScreen(context: viewModel.context))
    }
}

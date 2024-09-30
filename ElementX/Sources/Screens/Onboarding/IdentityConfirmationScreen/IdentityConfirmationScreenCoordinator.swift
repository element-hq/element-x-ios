//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import SwiftUI

struct IdentityConfirmationScreenCoordinatorParameters {
    let userSession: UserSessionProtocol
    let appSettings: AppSettings
    let userIndicatorController: UserIndicatorControllerProtocol
}

enum IdentityConfirmationScreenCoordinatorAction {
    case otherDevice
    case recoveryKey
    /// Only possible in debug builds.
    case skip
    case reset
    case logout
}

final class IdentityConfirmationScreenCoordinator: CoordinatorProtocol {
    private let parameters: IdentityConfirmationScreenCoordinatorParameters
    private let viewModel: IdentityConfirmationScreenViewModelProtocol
    
    private var cancellables = Set<AnyCancellable>()
 
    private let actionsSubject: PassthroughSubject<IdentityConfirmationScreenCoordinatorAction, Never> = .init()
    var actionsPublisher: AnyPublisher<IdentityConfirmationScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: IdentityConfirmationScreenCoordinatorParameters) {
        self.parameters = parameters
        
        viewModel = IdentityConfirmationScreenViewModel(userSession: parameters.userSession,
                                                        appSettings: parameters.appSettings,
                                                        userIndicatorController: parameters.userIndicatorController)
    }
    
    func start() {
        viewModel.actionsPublisher.sink { [weak self] action in
            guard let self else { return }
            
            MXLog.info("Coordinator: received view model action: \(action)")
            switch action {
            case .otherDevice:
                actionsSubject.send(.otherDevice)
            case .recoveryKey:
                actionsSubject.send(.recoveryKey)
            case .skip:
                actionsSubject.send(.skip)
            case .reset:
                actionsSubject.send(.reset)
            case .logout:
                actionsSubject.send(.logout)
            }
        }
        .store(in: &cancellables)
    }
        
    func toPresentable() -> AnyView {
        AnyView(IdentityConfirmationScreen(context: viewModel.context))
    }
}

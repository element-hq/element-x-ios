//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

struct SecureBackupLogoutConfirmationScreenCoordinatorParameters {
    let secureBackupController: SecureBackupControllerProtocol
    let homeserverReachabilityPublisher: CurrentValuePublisher<NetworkMonitorReachability, Never>
}

enum SecureBackupLogoutConfirmationScreenCoordinatorAction {
    case cancel
    case settings
    case logout
}

final class SecureBackupLogoutConfirmationScreenCoordinator: CoordinatorProtocol {
    private var viewModel: SecureBackupLogoutConfirmationScreenViewModelProtocol
    private let actionsSubject: PassthroughSubject<SecureBackupLogoutConfirmationScreenCoordinatorAction, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
    
    var actions: AnyPublisher<SecureBackupLogoutConfirmationScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: SecureBackupLogoutConfirmationScreenCoordinatorParameters) {
        viewModel = SecureBackupLogoutConfirmationScreenViewModel(secureBackupController: parameters.secureBackupController,
                                                                  homeserverReachabilityPublisher: parameters.homeserverReachabilityPublisher)
    }
    
    func start() {
        viewModel.actions.sink { [weak self] action in
            guard let self else { return }
            
            MXLog.info("Coordinator: received view model action: \(action)")
            
            switch action {
            case .cancel:
                actionsSubject.send(.cancel)
            case .settings:
                actionsSubject.send(.settings)
            case .logout:
                actionsSubject.send(.logout)
            }
        }
        .store(in: &cancellables)
    }
        
    func toPresentable() -> AnyView {
        AnyView(SecureBackupLogoutConfirmationScreen(context: viewModel.context))
    }
}

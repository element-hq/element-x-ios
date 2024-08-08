//
// Copyright 2022 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Combine
import SwiftUI

struct SecureBackupLogoutConfirmationScreenCoordinatorParameters {
    let secureBackupController: SecureBackupControllerProtocol
    let appMediator: AppMediatorProtocol
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
                                                                  appMediator: parameters.appMediator)
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

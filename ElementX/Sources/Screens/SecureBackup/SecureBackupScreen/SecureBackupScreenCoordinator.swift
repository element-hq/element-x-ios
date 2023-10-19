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

struct SecureBackupScreenCoordinatorParameters {
    let appSettings: AppSettings
    let secureBackupController: SecureBackupControllerProtocol
    weak var navigationStackCoordinator: NavigationStackCoordinator?
    weak var userIndicatorController: UserIndicatorControllerProtocol?
}

enum SecureBackupScreenCoordinatorAction { }

final class SecureBackupScreenCoordinator: CoordinatorProtocol {
    private let parameters: SecureBackupScreenCoordinatorParameters
    private var viewModel: SecureBackupScreenViewModelProtocol
    private let actionsSubject: PassthroughSubject<SecureBackupScreenCoordinatorAction, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
    
    var actions: AnyPublisher<SecureBackupScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: SecureBackupScreenCoordinatorParameters) {
        self.parameters = parameters
        
        viewModel = SecureBackupScreenViewModel(secureBackupController: parameters.secureBackupController,
                                                userIndicatorController: parameters.userIndicatorController,
                                                chatBackupDetailsURL: parameters.appSettings.chatBackupDetailsURL)
    }
    
    func start() {
        viewModel.actions.sink { [weak self] action in
            guard let self else { return }
            
            switch action {
            case .recoveryKey:
                let navigationStackCoordinator = NavigationStackCoordinator()
                let userIndicatorController = UserIndicatorController(rootCoordinator: navigationStackCoordinator)
                
                let recoveryKeyCoordinator = SecureBackupRecoveryKeyScreenCoordinator(parameters: .init(secureBackupController: parameters.secureBackupController,
                                                                                                        userIndicatorController: userIndicatorController))
                
                recoveryKeyCoordinator.actions.sink { [weak self] action in
                    guard let self else { return }
                    
                    parameters.navigationStackCoordinator?.setSheetCoordinator(nil)
                    
                    switch action {
                    case .cancel:
                        break
                    case .recoverySetUp:
                        showSuccessIndicator(title: L10n.screenRecoveryKeySetupSuccess)
                    case .recoveryChanged:
                        showSuccessIndicator(title: L10n.screenRecoveryKeyChangeSuccess)
                    case .recoveryFixed:
                        showSuccessIndicator(title: L10n.screenRecoveryKeyConfirmSuccess)
                    }
                }
                .store(in: &cancellables)
                
                navigationStackCoordinator.setRootCoordinator(recoveryKeyCoordinator, animated: true)
                
                parameters.navigationStackCoordinator?.setSheetCoordinator(userIndicatorController)
            case .keyBackup:
                let navigationStackCoordinator = NavigationStackCoordinator()
                let userIndicatorController = UserIndicatorController(rootCoordinator: navigationStackCoordinator)
                
                let keyBackupCoordinator = SecureBackupKeyBackupScreenCoordinator(parameters: .init(secureBackupController: parameters.secureBackupController,
                                                                                                    userIndicatorController: userIndicatorController))
                
                keyBackupCoordinator.actions.sink { [weak self] action in
                    switch action {
                    case .done:
                        self?.parameters.navigationStackCoordinator?.setSheetCoordinator(nil)
                    }
                }
                .store(in: &cancellables)
                
                navigationStackCoordinator.setRootCoordinator(keyBackupCoordinator, animated: true)
                
                parameters.navigationStackCoordinator?.setSheetCoordinator(userIndicatorController)
            }
        }
        .store(in: &cancellables)
    }
    
    func toPresentable() -> AnyView {
        AnyView(SecureBackupScreen(context: viewModel.context))
    }
    
    // MARK: - Private
    
    private func showSuccessIndicator(title: String) {
        parameters.userIndicatorController?.submitIndicator(.init(id: .init(),
                                                                  type: .modal(progress: .none, interactiveDismissDisabled: false, allowsInteraction: false),
                                                                  title: title,
                                                                  iconName: "checkmark",
                                                                  persistent: false))
    }
}

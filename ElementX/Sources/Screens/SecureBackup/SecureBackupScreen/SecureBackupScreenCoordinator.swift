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
    let clientProxy: ClientProxyProtocol
    weak var navigationStackCoordinator: NavigationStackCoordinator?
    let userIndicatorController: UserIndicatorControllerProtocol
    let mainWindow: UIWindow
}

enum SecureBackupScreenCoordinatorAction {
    case requestOIDCAuthorisation(URL)
}

final class SecureBackupScreenCoordinator: CoordinatorProtocol {
    private let parameters: SecureBackupScreenCoordinatorParameters
    private var viewModel: SecureBackupScreenViewModelProtocol
    
    private var cancellables = Set<AnyCancellable>()
    
    private let actionsSubject: PassthroughSubject<SecureBackupScreenCoordinatorAction, Never> = .init()
    var actions: AnyPublisher<SecureBackupScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: SecureBackupScreenCoordinatorParameters) {
        self.parameters = parameters
        
        viewModel = SecureBackupScreenViewModel(secureBackupController: parameters.clientProxy.secureBackupController,
                                                userIndicatorController: parameters.userIndicatorController,
                                                chatBackupDetailsURL: parameters.appSettings.chatBackupDetailsURL)
    }
    
    func start() {
        viewModel.actions.sink { [weak self] action in
            guard let self else { return }
            
            switch action {
            case .recoveryKey:
                let recoveryNavigationStackCoordinator = NavigationStackCoordinator()
                
                let recoveryKeyCoordinator = SecureBackupRecoveryKeyScreenCoordinator(parameters: .init(secureBackupController: parameters.clientProxy.secureBackupController,
                                                                                                        userIndicatorController: parameters.userIndicatorController,
                                                                                                        isModallyPresented: true))
                
                recoveryKeyCoordinator.actions.sink { [weak self] action in
                    guard let self else { return }
                    switch action {
                    case .cancel:
                        parameters.navigationStackCoordinator?.setSheetCoordinator(nil)
                    case .recoverySetUp:
                        showSuccessIndicator(title: L10n.screenRecoveryKeySetupSuccess)
                        parameters.navigationStackCoordinator?.setSheetCoordinator(nil)
                    case .recoveryChanged:
                        showSuccessIndicator(title: L10n.screenRecoveryKeyChangeSuccess)
                        parameters.navigationStackCoordinator?.setSheetCoordinator(nil)
                    case .recoveryFixed:
                        showSuccessIndicator(title: L10n.screenRecoveryKeyConfirmSuccess)
                        parameters.navigationStackCoordinator?.setSheetCoordinator(nil)
                    case .resetEncryption:
                        showEncryptionReset(recoveryNavigationStackCoordinator: recoveryNavigationStackCoordinator)
                    }
                }
                .store(in: &cancellables)
                
                recoveryNavigationStackCoordinator.setRootCoordinator(recoveryKeyCoordinator, animated: true)
                
                parameters.navigationStackCoordinator?.setSheetCoordinator(recoveryNavigationStackCoordinator)
            case .keyBackup:
                let navigationStackCoordinator = NavigationStackCoordinator()
                
                let keyBackupCoordinator = SecureBackupKeyBackupScreenCoordinator(parameters: .init(secureBackupController: parameters.clientProxy.secureBackupController,
                                                                                                    userIndicatorController: parameters.userIndicatorController))
                
                keyBackupCoordinator.actions.sink { [weak self] action in
                    switch action {
                    case .done:
                        self?.parameters.navigationStackCoordinator?.setSheetCoordinator(nil)
                    }
                }
                .store(in: &cancellables)
                
                navigationStackCoordinator.setRootCoordinator(keyBackupCoordinator, animated: true)
                
                parameters.navigationStackCoordinator?.setSheetCoordinator(navigationStackCoordinator)
            }
        }
        .store(in: &cancellables)
    }
    
    func toPresentable() -> AnyView {
        AnyView(SecureBackupScreen(context: viewModel.context))
    }
    
    // MARK: - Private
    
    private func showSuccessIndicator(title: String) {
        parameters.userIndicatorController.submitIndicator(.init(id: .init(),
                                                                 type: .modal(progress: .none, interactiveDismissDisabled: false, allowsInteraction: false),
                                                                 title: title,
                                                                 iconName: "checkmark",
                                                                 persistent: false))
    }
    
    private func showEncryptionReset(recoveryNavigationStackCoordinator: NavigationStackCoordinator) {
        let resetNavigationStackCoordinator = NavigationStackCoordinator()
        
        let coordinator = EncryptionResetScreenCoordinator(parameters: .init(clientProxy: parameters.clientProxy,
                                                                             navigationStackCoordinator: resetNavigationStackCoordinator,
                                                                             userIndicatorController: parameters.userIndicatorController))
        
        coordinator.actionsPublisher.sink { [weak self] action in
            guard let self else { return }
            
            switch action {
            case .cancel:
                recoveryNavigationStackCoordinator.setSheetCoordinator(nil)
            case .requestOIDCAuthorisation(let url):
                actionsSubject.send(.requestOIDCAuthorisation(url))
            case .resetFinished:
                parameters.navigationStackCoordinator?.setSheetCoordinator(nil) // Dismiss the recovery screen
                recoveryNavigationStackCoordinator.setSheetCoordinator(nil)
            }
        }
        .store(in: &cancellables)
        
        resetNavigationStackCoordinator.setRootCoordinator(coordinator)
        
        recoveryNavigationStackCoordinator.setSheetCoordinator(resetNavigationStackCoordinator)
    }
}

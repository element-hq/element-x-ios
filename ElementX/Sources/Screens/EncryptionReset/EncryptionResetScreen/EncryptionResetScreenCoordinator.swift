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

enum EncryptionResetScreenCoordinatorAction {
    case cancel
    case requestOIDCAuthorisation(URL)
    case resetFinished
}

struct EncryptionResetScreenCoordinatorParameters {
    let clientProxy: ClientProxyProtocol
    let navigationStackCoordinator: NavigationStackCoordinator
    let userIndicatorController: UserIndicatorControllerProtocol
}

final class EncryptionResetScreenCoordinator: CoordinatorProtocol {
    private let parameters: EncryptionResetScreenCoordinatorParameters
    private let viewModel: EncryptionResetScreenViewModelProtocol
    
    private var cancellables = Set<AnyCancellable>()
 
    private let actionsSubject: PassthroughSubject<EncryptionResetScreenCoordinatorAction, Never> = .init()
    var actionsPublisher: AnyPublisher<EncryptionResetScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: EncryptionResetScreenCoordinatorParameters) {
        self.parameters = parameters
        viewModel = EncryptionResetScreenViewModel(clientProxy: parameters.clientProxy,
                                                   userIndicatorController: parameters.userIndicatorController)
    }
    
    func start() {
        viewModel.actionsPublisher.sink { [weak self] action in
            MXLog.info("Coordinator: received view model action: \(action)")
            
            guard let self else { return }
            switch action {
            case .requestPassword:
                presentPasswordScreen()
            case .requestOIDCAuthorisation(let url):
                self.actionsSubject.send(.requestOIDCAuthorisation(url))
            case .resetFinished:
                self.actionsSubject.send(.resetFinished)
            case .cancel:
                self.actionsSubject.send(.cancel)
            }
        }
        .store(in: &cancellables)
    }
        
    func toPresentable() -> AnyView {
        AnyView(EncryptionResetScreen(context: viewModel.context))
    }
    
    // MARK: - Private
    
    private func presentPasswordScreen() {
        let coordinator = EncryptionResetPasswordScreenCoordinator(parameters: .init())
        
        coordinator.actionsPublisher.sink { [weak self] action in
            guard let self else { return }
            
            switch action {
            case .resetIdentity(let password):
                viewModel.continueResetFlowWith(password: password)
                parameters.navigationStackCoordinator.pop()
            }
        }
        .store(in: &cancellables)
        
        parameters.navigationStackCoordinator.push(coordinator)
    }
}

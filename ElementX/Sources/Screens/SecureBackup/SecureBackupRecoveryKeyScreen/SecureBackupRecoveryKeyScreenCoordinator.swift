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

struct SecureBackupRecoveryKeyScreenCoordinatorParameters {
    let secureBackupController: SecureBackupControllerProtocol
    let userIndicatorController: UserIndicatorControllerProtocol
    let isModallyPresented: Bool
}

enum SecureBackupRecoveryKeyScreenCoordinatorAction {
    case cancel
    case recoverySetUp
    case recoveryChanged
    case recoveryFixed
}

final class SecureBackupRecoveryKeyScreenCoordinator: CoordinatorProtocol {
    private var viewModel: SecureBackupRecoveryKeyScreenViewModelProtocol
    private let actionsSubject: PassthroughSubject<SecureBackupRecoveryKeyScreenCoordinatorAction, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
    
    var actions: AnyPublisher<SecureBackupRecoveryKeyScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: SecureBackupRecoveryKeyScreenCoordinatorParameters) {
        viewModel = SecureBackupRecoveryKeyScreenViewModel(secureBackupController: parameters.secureBackupController,
                                                           userIndicatorController: parameters.userIndicatorController,
                                                           isModallyPresented: parameters.isModallyPresented)
    }
    
    func start() {
        viewModel.actions.sink { [weak self] action in
            MXLog.info("Coordinator: received view model action: \(action)")
            
            guard let self else { return }
            switch action {
            case .cancel:
                self.actionsSubject.send(.cancel)
            case .done(let mode):
                switch mode {
                case .setupRecovery:
                    self.actionsSubject.send(.recoverySetUp)
                case .changeRecovery:
                    self.actionsSubject.send(.recoveryChanged)
                case .fixRecovery:
                    self.actionsSubject.send(.recoveryFixed)
                }
            }
        }
        .store(in: &cancellables)
    }
    
    func toPresentable() -> AnyView {
        AnyView(SecureBackupRecoveryKeyScreen(context: viewModel.context))
    }
}

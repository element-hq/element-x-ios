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

typealias SecureBackupScreenViewModelType = StateStoreViewModel<SecureBackupScreenViewState, SecureBackupScreenViewAction>

class SecureBackupScreenViewModel: SecureBackupScreenViewModelType, SecureBackupScreenViewModelProtocol {
    private let secureBackupController: SecureBackupControllerProtocol
    private let userIndicatorController: UserIndicatorControllerProtocol
    
    private var actionsSubject: PassthroughSubject<SecureBackupScreenViewModelAction, Never> = .init()
    var actions: AnyPublisher<SecureBackupScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(secureBackupController: SecureBackupControllerProtocol,
         userIndicatorController: UserIndicatorControllerProtocol,
         chatBackupDetailsURL: URL) {
        self.secureBackupController = secureBackupController
        self.userIndicatorController = userIndicatorController
        
        super.init(initialViewState: .init(chatBackupDetailsURL: chatBackupDetailsURL))
        
        secureBackupController.recoveryKeyState
            .receive(on: DispatchQueue.main)
            .weakAssign(to: \.state.recoveryKeyState, on: self)
            .store(in: &cancellables)
        
        secureBackupController.keyBackupState
            .receive(on: DispatchQueue.main)
            .weakAssign(to: \.state.keyBackupState, on: self)
            .store(in: &cancellables)
    }
    
    // MARK: - Public
    
    override func process(viewAction: SecureBackupScreenViewAction) {
        switch viewAction {
        case .recoveryKey:
            actionsSubject.send(.recoveryKey)
        case .keyBackup:
            switch secureBackupController.keyBackupState.value {
            case .unknown:
                enableBackup()
            case .enabled:
                actionsSubject.send(.keyBackup)
            default:
                break
            }
        }
    }
    
    // MARK: - Private
    
    private func enableBackup() {
        Task {
            let loadingIndicatorIdentifier = "SecureBackupScreenLoading"
            userIndicatorController.submitIndicator(.init(id: loadingIndicatorIdentifier, type: .modal, title: L10n.commonLoading, persistent: true))
            switch await secureBackupController.enable() {
            case .success:
                break
            case .failure(let error):
                MXLog.error("Failed enabling key backup with error: \(error)")
                state.bindings.alertInfo = .init(id: .init())
            }
            
            userIndicatorController.retractIndicatorWithId(loadingIndicatorIdentifier)
        }
    }
}

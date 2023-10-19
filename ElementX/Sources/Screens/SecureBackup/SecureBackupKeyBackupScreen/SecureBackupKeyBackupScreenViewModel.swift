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

typealias SecureBackupKeyBackupScreenViewModelType = StateStoreViewModel<SecureBackupKeyBackupScreenViewState, SecureBackupKeyBackupScreenViewAction>

class SecureBackupKeyBackupScreenViewModel: SecureBackupKeyBackupScreenViewModelType, SecureBackupKeyBackupScreenViewModelProtocol {
    private let secureBackupController: SecureBackupControllerProtocol
    
    private var actionsSubject: PassthroughSubject<SecureBackupKeyBackupScreenViewModelAction, Never> = .init()
    var actions: AnyPublisher<SecureBackupKeyBackupScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(secureBackupController: SecureBackupControllerProtocol, userIndicatorController: UserIndicatorControllerProtocol?) {
        self.secureBackupController = secureBackupController
        
        super.init(initialViewState: .init(mode: secureBackupController.keyBackupState.value.viewMode))
        
        secureBackupController.keyBackupState
            .receive(on: DispatchQueue.main)
            .sink { [weak userIndicatorController] state in
                let loadingIndicatorIdentifier = "SecureBackupKeyBackupScreenLoading"
                switch state {
                case .disabling, .enabling, .unknown:
                    userIndicatorController?.submitIndicator(.init(id: loadingIndicatorIdentifier, type: .modal, title: L10n.commonLoading, persistent: true))
                default:
                    userIndicatorController?.retractIndicatorWithId(loadingIndicatorIdentifier)
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public
    
    override func process(viewAction: SecureBackupKeyBackupScreenViewAction) {
        MXLog.info("View model: received view action: \(viewAction)")
        
        switch viewAction {
        case .cancel:
            actionsSubject.send(.done)
        case .toggleBackup:
            guard secureBackupController.keyBackupState.value == .enabled else {
                fatalError("Tried disabling backup when not enabled")
            }
            
            state.bindings.alertInfo = .init(id: .init(),
                                             title: L10n.screenKeyBackupDisableConfirmationTitle,
                                             message: L10n.screenKeyBackupDisableConfirmationDescription,
                                             primaryButton: .init(title: L10n.screenKeyBackupDisableConfirmationActionTurnOff, role: .destructive) { [weak self] in
                                                 self?.disableBackup()
                                             },
                                             secondaryButton: .init(title: L10n.actionCancel, role: .cancel, action: nil))
        }
    }
    
    // MARK: - Private
    
    private func enableBackup() {
        Task {
            switch await secureBackupController.enableBackup() {
            case .success:
                actionsSubject.send(.done)
            case .failure(let error):
                MXLog.error("Failed enabling key backup with error: \(error)")
                state.bindings.alertInfo = .init(id: .init())
            }
        }
    }
    
    private func disableBackup() {
        Task {
            switch await secureBackupController.disableBackup() {
            case .success:
                actionsSubject.send(.done)
            case .failure(let error):
                MXLog.error("Failed disabling key backup with error: \(error)")
                state.bindings.alertInfo = .init(id: .init())
            }
        }
    }
}

extension SecureBackupKeyBackupState {
    var viewMode: SecureBackupKeyBackupScreenViewMode {
        guard self == .enabled else {
            fatalError("Invalid key backup state")
        }
        
        return .disableBackup
    }
}

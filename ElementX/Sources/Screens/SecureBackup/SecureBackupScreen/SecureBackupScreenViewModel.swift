//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
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
        
        secureBackupController.recoveryState
            .receive(on: DispatchQueue.main)
            .weakAssign(to: \.state.recoveryState, on: self)
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

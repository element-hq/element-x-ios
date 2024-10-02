//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import SwiftUI

typealias SecureBackupKeyBackupScreenViewModelType = StateStoreViewModel<SecureBackupKeyBackupScreenViewState, SecureBackupKeyBackupScreenViewAction>

class SecureBackupKeyBackupScreenViewModel: SecureBackupKeyBackupScreenViewModelType, SecureBackupKeyBackupScreenViewModelProtocol {
    private let secureBackupController: SecureBackupControllerProtocol
    private let userIndicatorController: UserIndicatorControllerProtocol?
    
    private var actionsSubject: PassthroughSubject<SecureBackupKeyBackupScreenViewModelAction, Never> = .init()
    var actions: AnyPublisher<SecureBackupKeyBackupScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(secureBackupController: SecureBackupControllerProtocol, userIndicatorController: UserIndicatorControllerProtocol?) {
        self.secureBackupController = secureBackupController
        self.userIndicatorController = userIndicatorController
        
        super.init(initialViewState: .init(mode: secureBackupController.keyBackupState.value.viewMode))
        
        secureBackupController.keyBackupState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                switch state {
                case .disabling, .enabling, .unknown:
                    self?.showLoadingIndicator()
                default:
                    self?.dismissLoadingIndicator()
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
        
    private func disableBackup() {
        Task {
            switch await secureBackupController.disable() {
            case .success:
                actionsSubject.send(.done)
            case .failure(let error):
                MXLog.error("Failed disabling key backup with error: \(error)")
                state.bindings.alertInfo = .init(id: .init())
            }
            
            dismissLoadingIndicator()
        }
    }
    
    private static let loadingIndicatorIdentifier = "\(SecureBackupKeyBackupScreenViewModel.self)-Loading"
    
    private func showLoadingIndicator() {
        userIndicatorController?.submitIndicator(.init(id: Self.loadingIndicatorIdentifier, type: .modal, title: L10n.commonLoading, persistent: true))
    }
    
    private func dismissLoadingIndicator() {
        userIndicatorController?.retractIndicatorWithId(Self.loadingIndicatorIdentifier)
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

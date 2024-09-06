//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import SwiftUI

typealias SecureBackupRecoveryKeyScreenViewModelType = StateStoreViewModel<SecureBackupRecoveryKeyScreenViewState, SecureBackupRecoveryKeyScreenViewAction>

class SecureBackupRecoveryKeyScreenViewModel: SecureBackupRecoveryKeyScreenViewModelType, SecureBackupRecoveryKeyScreenViewModelProtocol {
    private let secureBackupController: SecureBackupControllerProtocol
    private let userIndicatorController: UserIndicatorControllerProtocol
    
    private var actionsSubject: PassthroughSubject<SecureBackupRecoveryKeyScreenViewModelAction, Never> = .init()
    var actions: AnyPublisher<SecureBackupRecoveryKeyScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(secureBackupController: SecureBackupControllerProtocol,
         userIndicatorController: UserIndicatorControllerProtocol,
         isModallyPresented: Bool) {
        self.secureBackupController = secureBackupController
        self.userIndicatorController = userIndicatorController
        
        super.init(initialViewState: .init(isModallyPresented: isModallyPresented,
                                           mode: secureBackupController.recoveryState.value.viewMode,
                                           bindings: .init()))
        
        secureBackupController.recoveryState
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] state in
                switch state {
                case .settingUp:
                    self?.showLoadingIndicator()
                default:
                    self?.hideLoadingIndicator()
                }
            })
            .store(in: &cancellables)
    }
    
    // MARK: - Public
    
    override func process(viewAction: SecureBackupRecoveryKeyScreenViewAction) {
        MXLog.info("View model: received view action: \(viewAction)")
        
        switch viewAction {
        case .generateKey:
            Task {
                switch await secureBackupController.generateRecoveryKey() {
                case .success(let key):
                    state.recoveryKey = key
                case .failure(let error):
                    MXLog.error("Failed generating recovery key with error: \(error)")
                    state.bindings.alertInfo = .init(id: .init())
                }
                
                hideLoadingIndicator()
            }
        case .copyKey:
            UIPasteboard.general.string = state.recoveryKey
            userIndicatorController.submitIndicator(.init(title: "Copied recovery key"))
            state.doneButtonEnabled = true
        case .keySaved:
            state.doneButtonEnabled = true
        case .confirmKey:
            Task {
                showLoadingIndicator()
                
                switch await secureBackupController.confirmRecoveryKey(state.bindings.confirmationRecoveryKey) {
                case .success:
                    actionsSubject.send(.done(mode: context.viewState.mode))
                case .failure(let error):
                    MXLog.error("Failed confirming recovery key with error: \(error)")
                    state.bindings.alertInfo = .init(id: .init())
                }
                
                hideLoadingIndicator()
            }
        case .cancel:
            actionsSubject.send(.cancel)
        case .done:
            state.bindings.alertInfo = .init(id: .init(),
                                             title: L10n.screenRecoveryKeySetupConfirmationTitle,
                                             message: L10n.screenRecoveryKeySetupConfirmationDescription,
                                             primaryButton: .init(title: L10n.actionCancel, role: .cancel, action: nil),
                                             secondaryButton: .init(title: L10n.actionContinue, action: { [weak self] in
                                                 guard let self else { return }
                                                 actionsSubject.send(.done(mode: context.viewState.mode))
                                             }))
        case .resetEncryption:
            actionsSubject.send(.resetEncryption)
        }
    }
    
    private static let loadingIndicatorIdentifier = "\(SecureBackupRecoveryKeyScreenViewModel.self)-Loading"
    
    private func showLoadingIndicator() {
        userIndicatorController.submitIndicator(UserIndicator(id: Self.loadingIndicatorIdentifier,
                                                              type: .modal,
                                                              title: L10n.commonLoading,
                                                              persistent: true))
    }
    
    private func hideLoadingIndicator() {
        userIndicatorController.retractIndicatorWithId(Self.loadingIndicatorIdentifier)
    }
}

extension SecureBackupRecoveryState {
    var viewMode: SecureBackupRecoveryKeyScreenViewMode {
        switch self {
        case .disabled:
            return .setupRecovery
        case .enabled:
            return .changeRecovery
        case .incomplete:
            return .fixRecovery
        default:
            return .unknown
        }
    }
}

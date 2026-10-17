//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias SecureBackupRecoveryKeyScreenViewModelType = StateStoreViewModelV2<SecureBackupRecoveryKeyScreenViewState, SecureBackupRecoveryKeyScreenViewAction>

class SecureBackupRecoveryKeyScreenViewModel: SecureBackupRecoveryKeyScreenViewModelType, SecureBackupRecoveryKeyScreenViewModelProtocol {
    private let secureBackupController: SecureBackupControllerProtocol
    private let userIndicatorController: UserIndicatorControllerProtocol
    
    @CancellableTask
    private var keyCheckTask: Task<Void, Never>?
    
    private var actionsSubject: PassthroughSubject<SecureBackupRecoveryKeyScreenViewModelAction, Never> = .init()
    var actions: AnyPublisher<SecureBackupRecoveryKeyScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(secureBackupController: SecureBackupControllerProtocol,
         userIndicatorController: UserIndicatorControllerProtocol,
         isModallyPresented: Bool,
         mode: SecureBackupRecoveryKeyScreenViewMode? = nil,
         presentationContext: SecureBackupRecoveryKeyScreenPresentationContext = .standard) {
        self.secureBackupController = secureBackupController
        self.userIndicatorController = userIndicatorController
        
        super.init(initialViewState: .init(isModallyPresented: isModallyPresented,
                                           mode: mode ?? secureBackupController.recoveryState.value.viewMode,
                                           presentationContext: presentationContext,
                                           bindings: .init()))
        
        // The user is taken straight to their new key. The SDK can't yet generate it without it also becoming active, so a
        // changed key replaces the existing one as soon as this screen opens.
        if state.mode == .setupRecovery || state.mode == .changeRecovery {
            process(viewAction: .generateKey)
        }
    }
    
    // MARK: - Public
    
    override func process(viewAction: SecureBackupRecoveryKeyScreenViewAction) {
        MXLog.info("View model: received view action: \(viewAction)")
        
        switch viewAction {
        case .generateKey:
            state.isGeneratingKey = true
            
            Task {
                switch await secureBackupController.generateRecoveryKey(withPassphrase: nil) {
                case .success(let key):
                    state.recoveryKey = key
                case .failure(let error):
                    MXLog.error("Failed generating recovery key with error: \(error)")
                    state.bindings.alertInfo = .init(id: .init())
                }
                
                state.isGeneratingKey = false
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
                    showSuccessIndicator(title: L10n.screenRecoveryKeyConfirmSuccess)
                    actionsSubject.send(.complete)
                case .failure(let error):
                    MXLog.error("Failed confirming recovery key with error: \(error)")
                    state.bindings.alertInfo = .init(id: .init(),
                                                     title: L10n.screenRecoveryKeyConfirmErrorTitle,
                                                     message: L10n.screenRecoveryKeyConfirmErrorContent)
                }
                
                hideLoadingIndicator()
            }
        case .cancel:
            actionsSubject.send(.complete)
        case .confirmKeySaved:
            state.bindings.alertInfo = .init(id: .init(),
                                             title: L10n.screenRecoveryKeySetupConfirmationTitle,
                                             message: L10n.screenRecoveryKeySetupConfirmationDescription,
                                             primaryButton: .init(title: L10n.actionContinue) { [weak self] in
                                                 self?.state.isCompleted = true
                                             },
                                             secondaryButton: .init(title: L10n.actionCancel, role: .cancel, action: nil))
        case .complete:
            actionsSubject.send(.complete)
        case .checkedKeyChanged:
            checkKey(after: .milliseconds(750))
        case .submitCheckedKey:
            checkKey(after: .zero)
        case .completeCheck:
            guard state.keyValidity == .valid else { return }
            state.isCompleted = true
        }
    }
    
    /// Checks the key the user has entered, waiting a moment so that it isn't checked while they are still typing.
    private func checkKey(after delay: Duration) {
        let key = state.bindings.confirmationRecoveryKey
        
        guard !key.isEmpty else {
            keyCheckTask = nil
            state.keyValidity = .unchecked
            return
        }
        
        state.keyValidity = .checking
        
        keyCheckTask = Task { [weak self] in
            try? await Task.sleep(for: delay)
            guard !Task.isCancelled, let self else { return }
            
            let result = await secureBackupController.checkRecoveryKey(key)
            guard !Task.isCancelled else { return }
            
            switch result {
            case .success:
                state.keyValidity = .valid
            case .failure:
                state.keyValidity = .invalid
            }
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
    
    private func showSuccessIndicator(title: String) {
        userIndicatorController.submitIndicator(.init(id: .init(),
                                                      type: .toast(progress: nil),
                                                      title: title,
                                                      icon: \.check,
                                                      persistent: false))
    }
}

private extension SecureBackupRecoveryState {
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

//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import SwiftUI

typealias AppLockSetupPINScreenViewModelType = StateStoreViewModel<AppLockSetupPINScreenViewState, AppLockSetupPINScreenViewAction>

class AppLockSetupPINScreenViewModel: AppLockSetupPINScreenViewModelType, AppLockSetupPINScreenViewModelProtocol {
    private let appLockService: AppLockServiceProtocol
    private var actionsSubject: PassthroughSubject<AppLockSetupPINScreenViewModelAction, Never> = .init()
    
    /// The PIN entered by the user in `.create` mode, used for confirmation.
    var newPIN: String?
    
    var actions: AnyPublisher<AppLockSetupPINScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(initialMode: AppLockSetupPINScreenMode, isMandatory: Bool, appLockService: AppLockServiceProtocol) {
        self.appLockService = appLockService
        
        super.init(initialViewState: AppLockSetupPINScreenViewState(mode: initialMode, isMandatory: isMandatory, bindings: .init(pinCode: "")))
        
        appLockService.numberOfPINAttempts
            .weakAssign(to: \.state.numberOfUnlockAttempts, on: self)
            .store(in: &cancellables)
        
        context.$viewState
            .map(\.bindings.pinCode)
            .removeDuplicates()
            .debounce(for: 0.1, scheduler: DispatchQueue.main) // Show the last digit for long enough to be read.
            .sink { [weak self] pinCode in
                guard pinCode.count == 4 else { return }
                self?.submit()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public
    
    override func process(viewAction: AppLockSetupPINScreenViewAction) {
        MXLog.info("View model: received view action: \(viewAction)")
        
        switch viewAction {
        case .cancel:
            actionsSubject.send(.cancel)
        case .forgotPIN:
            displayAlert(.confirmResetPIN)
        }
    }
    
    // MARK: - Private
    
    /// Handle the entered PIN code.
    private func submit() {
        switch state.mode {
        case .create:
            createPIN()
        case .confirm:
            confirmPIN()
        case .unlock:
            unlock()
        }
    }
    
    /// Handles a PIN input from the create mode. Transitions to confirmation if valid.
    private func createPIN() {
        let pinCode = state.bindings.pinCode
        if case let .failure(error) = appLockService.validate(pinCode) {
            MXLog.warning("PIN rejected: \(error)")
            displayAlert(.weakPIN)
            return
        }
        
        newPIN = pinCode
        state.mode = .confirm
        state.bindings.pinCode = ""
        state.numberOfConfirmAttempts = 0
    }
    
    /// Handles a PIN input from the confirm mode. Stores the pin if it matches.
    private func confirmPIN() {
        let pinCode = state.bindings.pinCode
        guard pinCode == newPIN else {
            MXLog.warning("PIN mismatch.")
            displayAlert(.pinMismatch)
            return
        }
        
        if case let .failure(error) = appLockService.setupPINCode(pinCode) {
            MXLog.warning("Failed to set PIN: \(error)")
            if case .keychainError = error {
                displayAlert(.failedToSetPIN)
                return
            } else {
                displayAlert(.weakPIN) // Shouldn't really happen but just in case.
                return
            }
        }
         
        actionsSubject.send(.complete)
    }
    
    /// Handles a PIN input for the unlock mode.
    private func unlock() {
        guard appLockService.unlock(with: state.bindings.pinCode) else {
            state.bindings.pinCode = ""
            if state.numberOfUnlockAttempts >= state.maximumAttempts {
                displayAlert(.forceLogout)
            }
            return
        }
        
        actionsSubject.send(.complete)
    }
    
    private func displayAlert(_ alertType: AppLockSetupPINScreenAlertType) {
        switch alertType {
        case .weakPIN:
            state.bindings.alertInfo = .init(id: alertType,
                                             title: L10n.screenAppLockSetupPinForbiddenDialogTitle,
                                             message: L10n.screenAppLockSetupPinForbiddenDialogContent,
                                             primaryButton: .init(title: L10n.actionOk) { self.state.bindings.pinCode = "" })
        case .pinMismatch:
            state.numberOfConfirmAttempts += 1
            state.bindings.alertInfo = .init(id: alertType,
                                             title: L10n.screenAppLockSetupPinMismatchDialogTitle,
                                             message: L10n.screenAppLockSetupPinMismatchDialogContent,
                                             primaryButton: .init(title: L10n.actionTryAgain) { self.restartCreateIfNeeded() })
        case .failedToSetPIN:
            state.bindings.alertInfo = .init(id: alertType)
        case .confirmResetPIN:
            state.bindings.alertInfo = .init(id: alertType,
                                             title: L10n.screenAppLockSignoutAlertTitle,
                                             message: L10n.screenAppLockSignoutAlertMessage,
                                             primaryButton: .init(title: L10n.actionOk) { self.forceLogout() },
                                             secondaryButton: .init(title: L10n.actionCancel, role: .cancel, action: nil))
        case .forceLogout:
            state.isLoggingOut = true // Disable the screen before showing the alert.
            state.bindings.alertInfo = .init(id: alertType,
                                             title: L10n.screenAppLockSignoutAlertTitle,
                                             message: L10n.screenAppLockSignoutAlertMessage,
                                             primaryButton: .init(title: L10n.actionOk) { self.forceLogout() })
        }
    }
    
    private func restartCreateIfNeeded() {
        state.bindings.pinCode = ""
        
        if state.numberOfConfirmAttempts >= state.maximumAttempts {
            newPIN = ""
            state.mode = .create
            state.numberOfConfirmAttempts = 0
        }
    }
    
    private func forceLogout() {
        state.isLoggingOut = true // Double call on failed to unlock, but not for forgot PIN.
        actionsSubject.send(.forceLogout)
    }
}

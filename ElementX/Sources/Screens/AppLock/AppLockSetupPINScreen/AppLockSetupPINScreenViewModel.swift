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
    }
    
    // MARK: - Public
    
    override func process(viewAction: AppLockSetupPINScreenViewAction) {
        MXLog.info("View model: received view action: \(viewAction)")
        
        switch viewAction {
        case .submitPINCode:
            submitPINCode()
        case .cancel:
            actionsSubject.send(.cancel)
        }
    }
    
    // MARK: - Private
    
    /// Handle the entered PIN code.
    private func submitPINCode() {
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
            handleError(.weakPIN)
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
            handleError(.pinMismatch)
            return
        }
        
        if case let .failure(error) = appLockService.setupPINCode(pinCode) {
            MXLog.warning("Failed to set PIN: \(error)")
            if case .keychainError = error {
                handleError(.failedToSetPIN)
                return
            } else {
                handleError(.weakPIN) // Shouldn't really happen but just in case.
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
                handleError(.forceLogout)
            }
            return
        }
        
        actionsSubject.send(.complete)
    }
    
    private func handleError(_ error: AppLockSetupPINScreenAlertType) {
        switch error {
        case .weakPIN:
            state.bindings.alertInfo = .init(id: error,
                                             title: L10n.screenAppLockSetupPinBlacklistedDialogTitle,
                                             message: L10n.screenAppLockSetupPinBlacklistedDialogContent,
                                             primaryButton: .init(title: L10n.actionOk) { self.state.bindings.pinCode = "" })
        case .pinMismatch:
            state.numberOfConfirmAttempts += 1
            state.bindings.alertInfo = .init(id: error,
                                             title: L10n.screenAppLockSetupPinMismatchDialogTitle,
                                             message: L10n.screenAppLockSetupPinMismatchDialogContent,
                                             primaryButton: .init(title: L10n.actionTryAgain) { self.restartCreateIfNeeded() })
        case .failedToSetPIN:
            state.bindings.alertInfo = .init(id: error)
        case .forceLogout:
            state.isLoggingOut = true // Disable the screen before showing the alert.
            state.bindings.alertInfo = .init(id: error,
                                             title: L10n.screenAppLockSignoutAlertTitle,
                                             message: L10n.screenAppLockSignoutAlertMessage,
                                             primaryButton: .init(title: L10n.actionOk) { self.actionsSubject.send(.forceLogout) })
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
}

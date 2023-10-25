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

typealias AppLockScreenViewModelType = StateStoreViewModel<AppLockScreenViewState, AppLockScreenViewAction>

class AppLockScreenViewModel: AppLockScreenViewModelType, AppLockScreenViewModelProtocol {
    private let appLockService: AppLockServiceProtocol
    private var actionsSubject: PassthroughSubject<AppLockScreenViewModelAction, Never> = .init()
    
    var actions: AnyPublisher<AppLockScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(appLockService: AppLockServiceProtocol) {
        self.appLockService = appLockService
        
        super.init(initialViewState: AppLockScreenViewState(bindings: .init()))
        
        appLockService.numberOfPINAttempts
            .weakAssign(to: \.state.numberOfPINAttempts, on: self)
            .store(in: &cancellables)
        
        showForceLogoutAlertIfNeeded()
    }
    
    // MARK: - Public
    
    override func process(viewAction: AppLockScreenViewAction) {
        MXLog.info("View model: received view action: \(viewAction)")
        
        switch viewAction {
        case .submitPINCode:
            guard appLockService.unlock(with: state.bindings.pinCode) else {
                handleInvalidPIN()
                return
            }
            actionsSubject.send(.appUnlocked)
        case .clearPINCode:
            state.bindings.pinCode = ""
        case .forgotPIN:
            handleForgotPIN()
        }
    }
    
    // MARK: - Private
    
    private func handleForgotPIN() {
        state.bindings.alertInfo = .init(id: .confirmResetPIN,
                                         title: L10n.screenAppLockSignoutAlertTitle,
                                         message: L10n.screenAppLockSignoutAlertMessage,
                                         primaryButton: .init(title: L10n.actionOk) { self.actionsSubject.send(.forceLogout) },
                                         secondaryButton: .init(title: L10n.actionCancel, role: .cancel, action: nil))
    }
    
    private func handleInvalidPIN() {
        MXLog.warning("Invalid PIN code entered.")
        showForceLogoutAlertIfNeeded()
    }
    
    private func showForceLogoutAlertIfNeeded() {
        if state.numberOfPINAttempts >= 3 {
            state.bindings.alertInfo = .init(id: .forcedLogout,
                                             title: L10n.screenAppLockSignoutAlertTitle,
                                             message: L10n.screenAppLockSignoutAlertMessage,
                                             primaryButton: .init(title: L10n.actionOk) { self.actionsSubject.send(.forceLogout) })
        }
    }
}

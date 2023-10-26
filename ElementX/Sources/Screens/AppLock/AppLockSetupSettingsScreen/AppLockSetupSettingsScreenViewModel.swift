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

typealias AppLockSetupSettingsScreenViewModelType = StateStoreViewModel<AppLockSetupSettingsScreenViewState, AppLockSetupSettingsScreenViewAction>

class AppLockSetupSettingsScreenViewModel: AppLockSetupSettingsScreenViewModelType, AppLockSetupSettingsScreenViewModelProtocol {
    private let appLockService: AppLockServiceProtocol
    private var actionsSubject: PassthroughSubject<AppLockSetupSettingsScreenViewModelAction, Never> = .init()
    
    var actions: AnyPublisher<AppLockSetupSettingsScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(appLockService: AppLockServiceProtocol) {
        self.appLockService = appLockService
        super.init(initialViewState: AppLockSetupSettingsScreenViewState(isMandatory: appLockService.isMandatory,
                                                                         biometryType: appLockService.biometryType,
                                                                         bindings: .init(enableBiometrics: appLockService.biometricUnlockEnabled)))
    }
    
    // MARK: - Public
    
    override func process(viewAction: AppLockSetupSettingsScreenViewAction) {
        MXLog.info("View model: received view action: \(viewAction)")
        
        switch viewAction {
        case .changePINCode:
            actionsSubject.send(.changePINCode)
        case .disable:
            showRemovePINAlert()
        case .enableBiometricsChanged:
            toggleBiometrics()
        }
    }
    
    // MARK: - Private
    
    private func toggleBiometrics() {
        if state.bindings.enableBiometrics {
            guard case .success = appLockService.enableBiometricUnlock() else {
                MXLog.error("Enabling biometric unlock failed.")
                state.bindings.enableBiometrics = false
                return
            }
            MXLog.info("Biometric unlock enabled.")
        } else {
            appLockService.disableBiometricUnlock()
            MXLog.info("Biometric unlock disabled.")
        }
    }
    
    /// Shows a confirmation alert to the user before removing their PIN code.
    private func showRemovePINAlert() {
        state.bindings.alertInfo = .init(id: .confirmRemovePINCode,
                                         title: L10n.screenAppLockSettingsRemovePinAlertTitle,
                                         message: L10n.screenAppLockSettingsRemovePinAlertMessage,
                                         primaryButton: .init(title: L10n.actionYes) { self.completeRemovePIN() },
                                         secondaryButton: .init(title: L10n.actionCancel, role: .cancel, action: nil))
    }
    
    /// Removes the user's PIN code, disabling the App Lock feature.
    private func completeRemovePIN() {
        appLockService.disable()
        actionsSubject.send(.appLockDisabled)
    }
}

//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
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
            Task { await toggleBiometrics() }
        }
    }
    
    // MARK: - Private
    
    private func toggleBiometrics() async {
        if state.bindings.enableBiometrics {
            guard case .success = appLockService.enableBiometricUnlock() else {
                MXLog.error("Enabling biometric unlock failed.")
                state.bindings.enableBiometrics = false
                return
            }
            MXLog.info("Biometric unlock enabled.")
            
            // Attempt unlock to trigger Face ID permissions alert.
            if appLockService.biometryType == .faceID,
               await appLockService.unlockWithBiometrics() != .unlocked {
                MXLog.info("Confirmation failed. Disabling biometric unlock.")
                state.bindings.enableBiometrics = false
                appLockService.disableBiometricUnlock()
            }
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

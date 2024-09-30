//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import SwiftUI

typealias AppLockSetupBiometricsScreenViewModelType = StateStoreViewModel<AppLockSetupBiometricsScreenViewState, AppLockSetupBiometricsScreenViewAction>

class AppLockSetupBiometricsScreenViewModel: AppLockSetupBiometricsScreenViewModelType, AppLockSetupBiometricsScreenViewModelProtocol {
    private let appLockService: AppLockServiceProtocol
    private var actionsSubject: PassthroughSubject<AppLockSetupBiometricsScreenViewModelAction, Never> = .init()
    
    var actions: AnyPublisher<AppLockSetupBiometricsScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(appLockService: AppLockServiceProtocol) {
        self.appLockService = appLockService
        super.init(initialViewState: AppLockSetupBiometricsScreenViewState(biometryType: appLockService.biometryType))
    }
    
    // MARK: - Public
    
    override func process(viewAction: AppLockSetupBiometricsScreenViewAction) {
        MXLog.info("View model: received view action: \(viewAction)")
        
        switch viewAction {
        case .allow:
            Task { await enableBiometricUnlock() }
        case .skip:
            disableBiometricUnlock()
        }
    }
    
    // MARK: - Private
    
    private func enableBiometricUnlock() async {
        guard case .success = appLockService.enableBiometricUnlock() else {
            MXLog.error("Enabling biometric unlock failed.")
            return
        }
        MXLog.info("Biometric unlock enabled.")
        
        // Attempt unlock to trigger Face ID permissions alert.
        if appLockService.biometryType == .faceID,
           await appLockService.unlockWithBiometrics() != .unlocked {
            MXLog.info("Confirmation failed. Disabling biometric unlock.")
            appLockService.disableBiometricUnlock()
        }
        
        actionsSubject.send(.continue)
    }
    
    private func disableBiometricUnlock() {
        appLockService.disableBiometricUnlock()
        MXLog.info("Biometric unlock disabled.")
        actionsSubject.send(.continue)
    }
}

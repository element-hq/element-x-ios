//
// Copyright 2023 New Vector Ltd
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
import LocalAuthentication

/// The service responsible for locking and unlocking the app.
class AppLockService: AppLockServiceProtocol {
    private let keychainController: KeychainControllerProtocol
    private let appSettings: AppSettings
    private let context: LAContext
    
    private let timer: AppLockTimer
    private let biometricPolicy: LAPolicy = .deviceOwnerAuthenticationWithBiometrics
    
    var isMandatory: Bool { appSettings.appLockIsMandatory }
    
    var isEnabled: Bool {
        do {
            guard appSettings.appLockFlowEnabled else { return false }
            return try keychainController.containsPINCode()
        } catch {
            MXLog.error("Keychain access error: \(error)")
            MXLog.error("Locking the app.")
            return true
        }
    }
    
    var biometryType: LABiometryType {
        updateBiometrics()
        guard context.evaluatedPolicyDomainState != nil else { return .none }
        return context.biometryType
    }
    
    var biometricUnlockEnabled: Bool {
        keychainController.containsPINCodeBiometryState()
    }
    
    var biometricUnlockTrusted: Bool {
        guard let state = keychainController.pinCodeBiometryState() else { return false }
        updateBiometrics()
        return state == context.evaluatedPolicyDomainState
    }
    
    var numberOfPINAttempts: AnyPublisher<Int, Never> { appSettings.$appLockNumberOfPINAttempts }
    
    private var disabledSubject: PassthroughSubject<Void, Never> = .init()
    var disabledPublisher: AnyPublisher<Void, Never> { disabledSubject.eraseToAnyPublisher() }
    
    init(keychainController: KeychainControllerProtocol, appSettings: AppSettings, context: LAContext = .init()) {
        self.keychainController = keychainController
        self.appSettings = appSettings
        self.context = context
        timer = AppLockTimer(gracePeriod: appSettings.appLockGracePeriod)
        
        updateBiometrics()
    }
    
    func setupPINCode(_ pinCode: String) -> Result<Void, AppLockServiceError> {
        let result = validate(pinCode)
        guard case .success = result else { return result }
        
        do {
            try keychainController.setPINCode(pinCode)
            return .success(())
        } catch {
            MXLog.error("Keychain access error: \(error)")
            return .failure(.keychainError)
        }
    }
    
    func validate(_ pinCode: String) -> Result<Void, AppLockServiceError> {
        guard pinCode.count == 4, pinCode.allSatisfy(\.isNumber) else { return .failure(.invalidPIN) }
        guard !appSettings.appLockPINCodeBlockList.contains(pinCode) else { return .failure(.weakPIN) }
        return .success(())
    }
    
    func enableBiometricUnlock() -> Result<Void, AppLockServiceError> {
        guard isEnabled else { return .failure(.pinNotSet) }
        guard let state = context.evaluatedPolicyDomainState else { return .failure(.biometricUnlockNotSupported) }
        
        do {
            try keychainController.setPINCodeBiometryState(state)
            return .success(())
        } catch {
            MXLog.error("Keychain access error: \(error)")
            return .failure(.keychainError)
        }
    }
    
    func disableBiometricUnlock() {
        keychainController.removePINCodeBiometryState()
    }
    
    func disable() {
        keychainController.removePINCode()
        keychainController.removePINCodeBiometryState()
        appSettings.appLockNumberOfPINAttempts = 0
        disabledSubject.send()
    }
    
    func applicationDidEnterBackground() {
        timer.applicationDidEnterBackground()
    }
    
    func computeNeedsUnlock(willEnterForegroundAt date: Date) -> Bool {
        timer.computeLockState(willEnterForegroundAt: date)
    }
    
    func unlock(with pinCode: String) -> Bool {
        guard pinCode == keychainController.pinCode() else {
            MXLog.warning("Wrong PIN entered.")
            appSettings.appLockNumberOfPINAttempts += 1
            return false
        }
        
        if biometricUnlockEnabled, !biometricUnlockTrusted {
            MXLog.info("Fixing trust for biometric unlock.")
            updateBiometrics()
            _ = enableBiometricUnlock()
        }
        
        return completeUnlock()
    }
    
    func unlockWithBiometrics() async -> Bool {
        guard biometryType != .none, biometricUnlockEnabled else {
            MXLog.error("Biometric unlock not setup.")
            return false
        }
        
        guard biometricUnlockTrusted else {
            MXLog.error("Biometrics have changed. PIN should be shown.")
            return false
        }
        
        do {
            guard try await context.evaluatePolicy(biometricPolicy, localizedReason: UntranslatedL10n.screenAppLockBiometricPromptReason) else {
                MXLog.warning("\(biometryType) failed.")
                return false
            }
            return completeUnlock()
        } catch {
            MXLog.error("\(biometryType) failed.")
            return false
        }
    }
    
    // MARK: - Private
    
    /// Queries the context for supported biometrics and enrolment state.
    private func updateBiometrics() {
        var error: NSError?
        context.canEvaluatePolicy(biometricPolicy, error: &error)
        
        if let error {
            MXLog.error("Biometrics error: \(error)")
        }
    }
    
    /// Shared logic for completing an unlock via a PIN or biometry.
    private func completeUnlock() -> Bool {
        timer.registerUnlock()
        appSettings.appLockNumberOfPINAttempts = 0
        return true
    }
}

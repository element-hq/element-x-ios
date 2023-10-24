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

import LocalAuthentication

/// The service responsible for locking and unlocking the app.
class AppLockService: AppLockServiceProtocol {
    private let keychainController: KeychainControllerProtocol
    private let appSettings: AppSettings
    private let context = LAContext()
    
    private let timer: AppLockTimer
    
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
    
    var biometryType: LABiometryType { context.biometryType }
    var biometricUnlockEnabled = false // Needs to be stored, not sure if in the keychain or defaults yet.
    
    init(keychainController: KeychainControllerProtocol, appSettings: AppSettings) {
        self.keychainController = keychainController
        self.appSettings = appSettings
        timer = AppLockTimer(gracePeriod: appSettings.appLockGracePeriod)
        
        configureBiometrics()
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
    
    func disable() {
        biometricUnlockEnabled = false
        keychainController.removePINCode()
    }
    
    func applicationDidEnterBackground() {
        timer.applicationDidEnterBackground()
    }
    
    func computeNeedsUnlock(willEnterForegroundAt date: Date) -> Bool {
        timer.computeLockState(willEnterForegroundAt: date)
    }
    
    func unlock(with pinCode: String) -> Bool {
        guard pinCode == keychainController.pinCode() else { return false }
        return completeUnlock()
    }
    
    func unlockWithBiometrics() -> Bool {
        guard biometryType != .none, biometricUnlockEnabled else { return false }
        return completeUnlock()
    }
    
    // MARK: - Private
    
    /// Queries the context for supported biometrics.
    private func configureBiometrics() {
        var error: NSError?
        context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        
        if let error {
            MXLog.error("Biometrics error: \(error)")
        }
    }
    
    /// Shared logic for completing an unlock via a PIN or biometry.
    private func completeUnlock() -> Bool {
        timer.registerUnlock()
        return true
    }
}

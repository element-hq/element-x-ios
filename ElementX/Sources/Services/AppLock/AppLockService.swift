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

enum AppLockServiceError: Error {
    /// The operation failed to access the keychain.
    case keychainError
    /// The PIN code was rejected as an insecure choice.
    case weakPIN
}

@MainActor
protocol AppLockServiceProtocol {
    /// The app has been configured to automatically lock with a PIN code.
    var isEnabled: Bool { get }
    /// The type of biometric authentication supported by the device.
    var biometryType: LABiometryType { get }
    /// Whether or not the user has enabled unlock via TouchID, FaceID or (possibly) OpticID.
    var biometricUnlockEnabled: Bool { get set }
    /// The app should be unlocked with a PIN code/biometrics before being presented.
    var needsUnlock: Bool { get }
    
    /// Sets the user's PIN code used to unlock the app.
    func setupPINCode(_ pinCode: String) -> Result<Void, AppLockServiceError>
    /// Disables the App Lock feature, removing the user's stored PIN code.
    func disable()
    
    /// Informs the service that the app has entered the background.
    func applicationDidEnterBackground()
    
    /// Attempt to unlock the app with the supplied PIN code.
    func unlock(with pinCode: String) -> Bool
    /// Attempt to unlock the app using FaceID or TouchID.
    func unlockWithBiometrics() -> Bool
}

/// The service responsible for locking and unlocking the app.
class AppLockService: AppLockServiceProtocol {
    private let keychainController: KeychainControllerProtocol
    private let appSettings: AppSettings
    private let context = LAContext()
    
    private var timer: AppLockTimer
    
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
    
    var needsUnlock: Bool {
        timer.needsUnlock()
    }
    
    init(keychainController: KeychainControllerProtocol, appSettings: AppSettings) {
        self.keychainController = keychainController
        self.appSettings = appSettings
        timer = AppLockTimer(gracePeriod: appSettings.appLockGracePeriod)
    }
    
    func setupPINCode(_ pinCode: String) -> Result<Void, AppLockServiceError> {
        do {
            guard !appSettings.appLockPINCodeBlockList.contains(pinCode) else { return .failure(.weakPIN) }
            try keychainController.setPINCode(pinCode)
            return .success(())
        } catch {
            MXLog.error("Keychain access error: \(error)")
            return .failure(.keychainError)
        }
    }
    
    func disable() {
        biometricUnlockEnabled = false
        keychainController.removePINCode()
    }
    
    func applicationDidEnterBackground() {
        timer.applicationDidEnterBackground()
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
    
    /// Shared logic for completing an unlock via a PIN or biometry.
    private func completeUnlock() -> Bool {
        timer.registerUnlock()
        return true
    }
}

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

enum AppLockServiceError: Error {
    /// The operation failed to access the keychain.
    case keychainError
    /// The PIN code was rejected because it isn't long enough, or contains invalid characters.
    case invalidPIN
    /// The PIN code was rejected as an insecure choice.
    case weakPIN
    /// A PIN code hasn't been set yet.
    case pinNotSet
    /// Attempting to use biometric unlock when it isn't yet supported on this device.
    case biometricUnlockNotSupported
}

@MainActor
protocol AppLockServiceProtocol: AnyObject {
    /// The use of a PIN code is mandatory for this device.
    var isMandatory: Bool { get }
    /// The app has been configured to automatically lock with a PIN code.
    var isEnabled: Bool { get }
    
    /// The type of biometric authentication supported by the device.
    var biometryType: LABiometryType { get }
    /// Whether or not the user has enabled unlock via TouchID, FaceID or (possibly) OpticID.
    var biometricUnlockEnabled: Bool { get }
    /// Whether TouchID, FaceID or (possibly) OpticID are trusted, or if the app needs the user
    /// to re-enter their PIN code to re-enable the feature (i.e. to accept a new face or fingerprint).
    var biometricUnlockTrusted: Bool { get }
    
    /// A publisher that advertises when the service has been disabled.
    var disabledPublisher: AnyPublisher<Void, Never> { get }
    
    /// Sets the user's PIN code used to unlock the app.
    func setupPINCode(_ pinCode: String) -> Result<Void, AppLockServiceError>
    /// Validates the supplied PIN code is long enough, only contains digits and isn't a weak choice.
    func validate(_ pinCode: String) -> Result<Void, AppLockServiceError>
    /// Enables the use of Touch ID/Face ID as an alternative to the PIN code.
    func enableBiometricUnlock() -> Result<Void, AppLockServiceError>
    /// Disables the use of Touch ID/Face ID as an alternative to the PIN code.
    func disableBiometricUnlock()
    /// Disables the App Lock feature, removing the user's stored PIN code.
    func disable()
    
    /// Informs the service that the app has entered the background.
    func applicationDidEnterBackground()
    /// Decides whether the app should be unlocked with a PIN code/biometrics on foregrounding.
    func computeNeedsUnlock(willEnterForegroundAt date: Date) -> Bool
    
    /// Attempt to unlock the app with the supplied PIN code.
    func unlock(with pinCode: String) -> Bool
    /// Attempt to unlock the app using FaceID or TouchID.
    func unlockWithBiometrics() async -> Bool
    
    /// The number of attempts the user had made to unlock with a PIN code.
    ///
    /// Note: We don't track the biometric attempts as LAContext does that automatically.
    var numberOfPINAttempts: AnyPublisher<Int, Never> { get }
}

// sourcery: AutoMockable
extension AppLockServiceProtocol { }

extension AppLockServiceMock {
    static func mock(pinCode: String? = "2023", isMandatory: Bool = false, biometryType: LABiometryType = .faceID, numberOfPINAttempts: Int = 0) -> AppLockServiceMock {
        let mock = AppLockServiceMock()
        mock.isEnabled = pinCode != nil
        mock.isMandatory = isMandatory
        mock.numberOfPINAttempts = CurrentValueSubject<Int, Never>(numberOfPINAttempts).eraseToAnyPublisher()
        mock.underlyingBiometryType = biometryType
        mock.underlyingBiometricUnlockEnabled = biometryType != .none
        mock.unlockWithClosure = { $0 == pinCode }
        return mock
    }
}

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

@MainActor
protocol AppLockServiceProtocol {
    /// The app has been configured to automatically lock with a PIN code.
    var isEnabled: Bool { get }
    /// The app can additionally be unlocked using FaceID or TouchID.
    var supportsBiometrics: Bool { get }
    /// The app should be unlocked with a PIN code/biometrics before being presented.
    var needsUnlock: Bool { get }
    
    /// Attempt to unlock the app with the supplied PIN code.
    func unlock(with pinCode: String) -> Bool
    /// Attempt to unlock the app using FaceID or TouchID.
    func unlockWithBiometrics() -> Bool
}

class AppLockService: AppLockServiceProtocol {
    private let keychainController: KeychainControllerProtocol
    
    var isEnabled: Bool { true }
    var supportsBiometrics: Bool { true }
    var needsUnlock: Bool { true }
    
    init(keychainController: KeychainControllerProtocol) {
        self.keychainController = keychainController
    }
    
    func unlock(with pinCode: String) -> Bool {
        true
    }
    
    func unlockWithBiometrics() -> Bool {
        guard supportsBiometrics else { return false }
        return true
    }
}

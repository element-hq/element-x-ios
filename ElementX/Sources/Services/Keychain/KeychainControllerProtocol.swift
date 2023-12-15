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

import Foundation
import MatrixRustSDK

struct KeychainCredentials {
    let userID: String
    let restorationToken: RestorationToken
}

// sourcery: AutoMockable
protocol KeychainControllerProtocol: ClientSessionDelegate {
    // MARK: Restoration Tokens
    
    func setRestorationToken(_ restorationToken: RestorationToken, forUsername: String)
    func restorationTokens() -> [KeychainCredentials]
    func removeRestorationTokenForUsername(_ username: String)
    func removeAllRestorationTokens()
    
    // MARK: App Secrets
    
    /// Whether or not an App Lock PIN code has been set.
    func containsPINCode() throws -> Bool
    /// Sets a new PIN code for App Lock.
    func setPINCode(_ pinCode: String) throws
    /// The PIN code required to unlock the app.
    func pinCode() -> String?
    /// Removes the App Lock PIN code.
    func removePINCode()
    /// Whether or not PIN code biometric state has been set.
    func containsPINCodeBiometricState() -> Bool
    /// Sets the PIN code biometric state for App Lock.
    func setPINCodeBiometricState(_ state: Data) throws
    /// The PIN code biometric state required to use Touch/Face ID to unlock the app.
    func pinCodeBiometricState() -> Data?
    /// Removes the App Lock PIN code biometric state.
    func removePINCodeBiometricState()
}

//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
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

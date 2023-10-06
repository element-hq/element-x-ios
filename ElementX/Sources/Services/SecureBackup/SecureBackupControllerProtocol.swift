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
import Foundation

enum SecureBackupRecoveryKeyState {
    case unknown
    case disabled
    case enabled
    /// Recovery is not set up properly, the user will need to re-enter it so we can cleanup
    /// https://github.com/vector-im/element-meta/issues/2107
    case incomplete
    case settingUp
}

enum SecureBackupKeyBackupState {
    case unknown
    case enabling
    case enabled
    case disabling
    case disabled
}

enum SecureBackupControllerError: Error {
    case failedEnablingKeyBackup
    case failedDisablingKeyBackup
    
    case failedGeneratingRecoveryKey
    case failedConfirmingRecoveryKey
}

// sourcery: AutoMockable
protocol SecureBackupControllerProtocol {
    var recoveryKeyState: CurrentValuePublisher<SecureBackupRecoveryKeyState, Never> { get }
    
    var keyBackupState: CurrentValuePublisher<SecureBackupKeyBackupState, Never> { get }
    
    func enableBackup() async -> Result<Void, SecureBackupControllerError>
    func disableBackup() async -> Result<Void, SecureBackupControllerError>
    
    func generateRecoveryKey() async -> Result<String, SecureBackupControllerError>
    func confirmRecoveryKey(_ key: String) async -> Result<Void, SecureBackupControllerError>
}

extension SecureBackupControllerMock {
    convenience init(keyBackupState: SecureBackupKeyBackupState, recoveryKeyState: SecureBackupRecoveryKeyState) {
        self.init()
        underlyingKeyBackupState = CurrentValueSubject<SecureBackupKeyBackupState, Never>(keyBackupState).asCurrentValuePublisher()
        underlyingRecoveryKeyState = CurrentValueSubject<SecureBackupRecoveryKeyState, Never>(recoveryKeyState).asCurrentValuePublisher()
    }
}

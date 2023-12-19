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
    /// https://github.com/element-hq/element-meta/issues/2107
    case incomplete
    case settingUp
}

enum SecureBackupKeyBackupState {
    /// Any state where backups couldn't have been enabled but we didn't explicitly disable them on this client.
    /// For all intents and purposes, within the client, this can be treated as `disabled`.
    case unknown
    case enabling
    case enabled
    case disabling
}

enum SecureBackupControllerError: Error {
    case failedEnablingBackup
    case failedDisablingBackup
    
    case failedGeneratingRecoveryKey
    case failedConfirmingRecoveryKey
    
    case failedFetchingSessionState
    
    case failedUploadingForBackup
}

// sourcery: AutoMockable
protocol SecureBackupControllerProtocol {
    var recoveryKeyState: CurrentValuePublisher<SecureBackupRecoveryKeyState, Never> { get }
    
    var keyBackupState: CurrentValuePublisher<SecureBackupKeyBackupState, Never> { get }
    
    func enable() async -> Result<Void, SecureBackupControllerError>
    func disable() async -> Result<Void, SecureBackupControllerError>
    
    func generateRecoveryKey() async -> Result<String, SecureBackupControllerError>
    func confirmRecoveryKey(_ key: String) async -> Result<Void, SecureBackupControllerError>
    
    func isLastSession() async -> Result<Bool, SecureBackupControllerError>
    
    func waitForKeyBackupUpload() async -> Result<Void, SecureBackupControllerError>
}

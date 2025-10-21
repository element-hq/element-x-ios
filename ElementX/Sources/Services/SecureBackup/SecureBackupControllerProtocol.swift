//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation

enum SecureBackupRecoveryState {
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

/// Represents the progress towards a complete backup before logging out.
enum SecureBackupSteadyState {
    case waiting
    case uploading(uploadedKeyCount: Int, totalKeyCount: Int)
    case error
    case done
}

enum SecureBackupControllerError: Error {
    case failedEnablingBackup
    case failedDisablingBackup
    
    case failedGeneratingRecoveryKey
    case failedConfirmingRecoveryKey
        
    case failedUploadingForBackup
}

// sourcery: AutoMockable
protocol SecureBackupControllerProtocol {
    var recoveryState: CurrentValuePublisher<SecureBackupRecoveryState, Never> { get }
    
    var keyBackupState: CurrentValuePublisher<SecureBackupKeyBackupState, Never> { get }
    
    func enable() async -> Result<Void, SecureBackupControllerError>
    func disable() async -> Result<Void, SecureBackupControllerError>
    
    func generateRecoveryKey() async -> Result<String, SecureBackupControllerError>
    func confirmRecoveryKey(_ key: String) async -> Result<Void, SecureBackupControllerError>
    
    func waitForKeyBackupUpload(uploadStateSubject: CurrentValueSubject<SecureBackupSteadyState, Never>) async -> Result<Void, SecureBackupControllerError>
}

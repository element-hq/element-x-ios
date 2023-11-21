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
import MatrixRustSDK

class SecureBackupController: SecureBackupControllerProtocol {
    private let encryption: Encryption
    
    private let recoveryKeyStateSubject = CurrentValueSubject<SecureBackupRecoveryKeyState, Never>(.unknown)
    private let keyBackupStateSubject = CurrentValueSubject<SecureBackupKeyBackupState, Never>(.unknown)
    
    private var backupStateListenerTaskHandle: TaskHandle?
    private var recoveryStateListenerTaskHandle: TaskHandle?
    
    /// Used to dedupe remote backup state requests
    @CancellableTask private var remoteBackupStateTask: Task<Void, Error>?
    
    var recoveryKeyState: CurrentValuePublisher<SecureBackupRecoveryKeyState, Never> {
        recoveryKeyStateSubject.asCurrentValuePublisher()
    }
    
    var keyBackupState: CurrentValuePublisher<SecureBackupKeyBackupState, Never> {
        keyBackupStateSubject.asCurrentValuePublisher()
    }
    
    init(encryption: Encryption) {
        self.encryption = encryption
        
        backupStateListenerTaskHandle = encryption.backupStateListener(listener: SecureBackupControllerBackupStateListener { [weak self] state in
            guard let self else { return }
            
            keyBackupStateSubject.send(state.keyBackupState)
            
            if case .unknown = state {
                updateBackupStateFromRemote()
            }
        })
        
        recoveryStateListenerTaskHandle = encryption.recoveryStateListener(listener: SecureBackupRecoveryStateListener { [weak self] state in
            guard let self else { return }
            
            switch state {
            case .unknown:
                recoveryKeyStateSubject.send(.unknown)
            case .enabled:
                recoveryKeyStateSubject.send(.enabled)
            case .disabled:
                recoveryKeyStateSubject.send(.disabled)
            case .incomplete:
                recoveryKeyStateSubject.send(.incomplete)
            }
        })
        
        updateBackupStateFromRemote()
    }
    
    func enable() async -> Result<Void, SecureBackupControllerError> {
        do {
            try await encryption.enableBackups()
        } catch {
            return .failure(.failedEnablingBackup)
        }
        
        return .success(())
    }
    
    func disable() async -> Result<Void, SecureBackupControllerError> {
        do {
            try await encryption.disableRecovery()
        } catch {
            return .failure(.failedDisablingBackup)
        }
        
        return .success(())
    }
    
    func generateRecoveryKey() async -> Result<String, SecureBackupControllerError> {
        do {
            guard recoveryKeyState.value == .disabled else {
                let key = try await encryption.resetRecoveryKey()
                return .success(key)
            }
            
            let recoveryKey = try await encryption.enableRecovery(waitForBackupsToUpload: false, progressListener: SecureBackupEnableRecoveryProgressListener { [weak self] state in
                guard let self else { return }
                
                switch state {
                case .creatingBackup:
                    recoveryKeyStateSubject.send(.settingUp)
                case .creatingRecoveryKey:
                    recoveryKeyStateSubject.send(.settingUp)
                case .backingUp:
                    recoveryKeyStateSubject.send(.settingUp)
                case .done:
                    recoveryKeyStateSubject.send(.enabled)
                }
            })
            
            return .success(recoveryKey)
        } catch {
            return .failure(.failedGeneratingRecoveryKey)
        }
    }
    
    func confirmRecoveryKey(_ key: String) async -> Result<Void, SecureBackupControllerError> {
        do {
            try await encryption.fixRecoveryIssues(recoveryKey: key)
            return .success(())
        } catch {
            return .failure(.failedConfirmingRecoveryKey)
        }
    }
    
    func isLastSession() async -> Result<Bool, SecureBackupControllerError> {
        do {
            return try await .success(encryption.isLastDevice())
        } catch {
            return .failure(.failedFetchingSessionState)
        }
    }
    
    func waitForKeyBackupUpload() async -> Result<Void, SecureBackupControllerError> {
        do {
            try await encryption.waitForBackupUploadSteadyState(progressListener: nil)
            return .success(())
        } catch let error as SteadyStateError {
            switch error {
            case .BackupDisabled:
                MXLog.error("Key backup disabled, continuing logout.")
                return .success(())
            case .Connection, .Laged:
                MXLog.error("Key backup upload failure: \(error)")
                return .failure(.failedUploadingForBackup)
            }
        } catch {
            MXLog.error("Unknown key backup upload failure")
            return .failure(.failedUploadingForBackup)
        }
    }
    
    // MARK: - Private
    
    private func updateBackupStateFromRemote(retry: Bool = true) {
        remoteBackupStateTask = Task {
            do {
                let backupExists = try await self.encryption.backupExistsOnServer()
                
                if Task.isCancelled {
                    return
                }
                
                if !backupExists {
                    keyBackupStateSubject.send(.disabled)
                }
            } catch {
                MXLog.error("Failed retrieving remote backup state with error: \(error)")
                
                if retry {
                    updateBackupStateFromRemote(retry: false)
                }
            }
        }
    }
}

private final class SecureBackupControllerBackupStateListener: BackupStateListener {
    private let onUpdateClosure: (BackupState) -> Void
    
    init(_ onUpdateClosure: @escaping (BackupState) -> Void) {
        self.onUpdateClosure = onUpdateClosure
    }
    
    func onUpdate(status: BackupState) {
        onUpdateClosure(status)
    }
}

private final class SecureBackupRecoveryStateListener: RecoveryStateListener {
    private let onUpdateClosure: (RecoveryState) -> Void
    
    init(_ onUpdateClosure: @escaping (RecoveryState) -> Void) {
        self.onUpdateClosure = onUpdateClosure
    }
    
    func onUpdate(status: RecoveryState) {
        onUpdateClosure(status)
    }
}

private final class SecureBackupEnableRecoveryProgressListener: EnableRecoveryProgressListener {
    private let onUpdateClosure: (EnableRecoveryProgress) -> Void
    
    init(_ onUpdateClosure: @escaping (EnableRecoveryProgress) -> Void) {
        self.onUpdateClosure = onUpdateClosure
    }
    
    func onUpdate(status: EnableRecoveryProgress) {
        onUpdateClosure(status)
    }
}

extension BackupState {
    var keyBackupState: SecureBackupKeyBackupState {
        switch self {
        case .unknown:
            return .unknown
        case .creating:
            return .enabling
        case .enabling:
            return .enabling
        case .resuming:
            return .enabled
        case .enabled:
            return .enabled
        case .downloading:
            return .enabled
        case .disabling:
            return .disabling
        }
    }
}

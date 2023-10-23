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

class SecureBackupController: SecureBackupControllerProtocol {
    private let recoveryKeyStateSubject = CurrentValueSubject<SecureBackupRecoveryKeyState, Never>(.disabled)
    private let keyBackupStateSubject = CurrentValueSubject<SecureBackupKeyBackupState, Never>(.disabled)
    
    var recoveryKeyState: CurrentValuePublisher<SecureBackupRecoveryKeyState, Never> {
        recoveryKeyStateSubject.asCurrentValuePublisher()
    }
    
    var keyBackupState: CurrentValuePublisher<SecureBackupKeyBackupState, Never> {
        keyBackupStateSubject.asCurrentValuePublisher()
    }
    
    var isLastSession: Bool {
        #warning("FIXME")
        return true
    }
    
    func enableBackup() async -> Result<Void, SecureBackupControllerError> {
        keyBackupStateSubject.send(.enabling)
        
        try? await Task.sleep(for: .seconds(1))
        
        keyBackupStateSubject.send(.enabled)
        
        return .success(())
    }
    
    func disableBackup() async -> Result<Void, SecureBackupControllerError> {
        keyBackupStateSubject.send(.disabling)
        
        try? await Task.sleep(for: .seconds(1))
        
        keyBackupStateSubject.send(.disabled)
        
        return .success(())
    }
    
    static var wohoo = 0
    
    func generateRecoveryKey() async -> Result<String, SecureBackupControllerError> {
        recoveryKeyStateSubject.send(.settingUp)
        
        try? await Task.sleep(for: .seconds(1))
        
        if Self.wohoo > 0, Self.wohoo % 2 == 1 {
            recoveryKeyStateSubject.send(.incomplete)
        } else {
            recoveryKeyStateSubject.send(.enabled)
        }
        
        Self.wohoo += 1
        
        return .success(UUID().uuidString)
    }
    
    func confirmRecoveryKey(_ key: String) async -> Result<Void, SecureBackupControllerError> {
        recoveryKeyStateSubject.send(.settingUp)
        
        try? await Task.sleep(for: .seconds(1))
        
        recoveryKeyStateSubject.send(.enabled)
        
        return .success(())
    }
    
    func waitForKeyBackup() async {
        try? await Task.sleep(for: .seconds(5))
    }
}

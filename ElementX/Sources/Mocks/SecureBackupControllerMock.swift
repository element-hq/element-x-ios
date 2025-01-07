//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation

extension SecureBackupControllerMock {
    struct Configuration {
        var recoveryState: SecureBackupRecoveryState = .enabled
        var keyBackupState: SecureBackupKeyBackupState = .enabled
    }
    
    convenience init(_ configuration: Configuration) {
        self.init()
        
        let recoveryStateSubject = CurrentValueSubject<SecureBackupRecoveryState, Never>(configuration.recoveryState)
        underlyingRecoveryState = .init(recoveryStateSubject)
        
        let keyBackupStateSubject = CurrentValueSubject<SecureBackupKeyBackupState, Never>(configuration.keyBackupState)
        underlyingKeyBackupState = .init(keyBackupStateSubject)
        
        disableClosure = {
            recoveryStateSubject.send(.disabled)
            keyBackupStateSubject.send(.unknown)
            return .success(())
        }
        
        enableClosure = {
            recoveryStateSubject.send(.disabled)
            keyBackupStateSubject.send(.enabled)
            return .success(())
        }
        
        generateRecoveryKeyClosure = {
            recoveryStateSubject.send(.enabled)
            return .success("a1B2 C3d4 E5F6 g7H8 i9J0 K1l2 M3n4 O5p6 Q7R8 s9T0 U1v2 W3X4")
        }
        
        confirmRecoveryKeyClosure = { _ in
            recoveryStateSubject.send(.enabled)
            return .success(())
        }
    }
}

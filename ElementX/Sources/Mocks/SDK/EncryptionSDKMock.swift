//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRustSDK
import MatrixRustSDKMocks

nonisolated extension EncryptionSDKMock {
    struct Configuration {
        var verificationState: VerificationState = .unknown
    }
    
    convenience init(_ configuration: Configuration) {
        self.init()
        
        verificationStateReturnValue = configuration.verificationState
        backupStateListenerListenerReturnValue = TaskHandleSDKMock()
        recoveryStateListenerListenerReturnValue = TaskHandleSDKMock()
        verificationStateListenerListenerReturnValue = TaskHandleSDKMock()
    }
}

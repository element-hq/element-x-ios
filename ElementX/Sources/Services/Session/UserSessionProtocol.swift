//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import Foundation

enum UserSessionCallback {
    case didReceiveAuthError(isSoftLogout: Bool)
}

struct SessionSecurityState: Equatable {
    let verificationState: SessionVerificationState
    let recoveryState: SecureBackupRecoveryState
}

// sourcery: AutoMockable
protocol UserSessionProtocol {
    var clientProxy: ClientProxyProtocol { get }
    var mediaProvider: MediaProviderProtocol { get }
    var voiceMessageMediaManager: VoiceMessageMediaManagerProtocol { get }
    
    var sessionSecurityStatePublisher: CurrentValuePublisher<SessionSecurityState, Never> { get }
    
    var callbacks: PassthroughSubject<UserSessionCallback, Never> { get }
}

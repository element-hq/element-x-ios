//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
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
protocol UserSessionProtocol: Sendable {
    var clientProxy: ClientProxyProtocol { get }
    var userSettings: UserSettings { get }
    var userHooks: UserHooks { get }
    
    var mediaProvider: MediaProviderProtocol { get }
    var voiceMessageMediaManager: VoiceMessageMediaManagerProtocol { get }
    var liveLocationService: LiveLocationServiceProtocol { get }
    /// Scans media content, `nil` when no content scanner is configured for the server.
    var contentScannerService: ContentScannerServiceProtocol? { get }
    var notificationService: NotificationServiceProtocol { get }
    
    var sessionSecurityStatePublisher: CurrentValuePublisher<SessionSecurityState, Never> { get }
    
    var callbacks: PassthroughSubject<UserSessionCallback, Never> { get }
}

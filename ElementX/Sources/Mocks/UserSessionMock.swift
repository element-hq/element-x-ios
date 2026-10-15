//
// Copyright 2025 Element Creations Ltd.
// Copyright 2024-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation

struct UserSessionMockConfiguration {
    var clientProxy: ClientProxyProtocol = ClientProxyMock(.init())
    var userSettings: UserSettings = .mock()
    var userHooks = UserHooks()
    var contentScannerService: ContentScannerServiceProtocol?
    var liveLocationService: LiveLocationServiceProtocol = LiveLocationServiceMock(.init())
    var notificationService: NotificationServiceProtocol = NotificationServiceMock(.init())
}

@MainActor extension UserSessionMock {
    convenience init(_ configuration: UserSessionMockConfiguration) {
        self.init()
        
        clientProxy = configuration.clientProxy
        userSettings = configuration.userSettings
        userHooks = configuration.userHooks
        callbacks = .init()
        
        mediaProvider = MediaProviderMock(.init())
        voiceMessageMediaManager = VoiceMessageMediaManagerMock()
        contentScannerService = configuration.contentScannerService
        
        sessionSecurityStatePublisher = CurrentValueSubject<SessionSecurityState, Never>(.init(verificationState: .verified, recoveryState: .enabled)).asCurrentValuePublisher()
        
        liveLocationService = configuration.liveLocationService
        notificationService = configuration.notificationService
    }
}

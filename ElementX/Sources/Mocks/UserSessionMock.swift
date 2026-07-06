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
    var contentScannerService: ContentScannerServiceProtocol?
}

@MainActor extension UserSessionMock {
    convenience init(_ configuration: UserSessionMockConfiguration) {
        self.init()
        
        clientProxy = configuration.clientProxy
        mediaProvider = MediaProviderMock(.init())
        voiceMessageMediaManager = VoiceMessageMediaManagerMock()
        contentScannerService = configuration.contentScannerService
        
        sessionSecurityStatePublisher = CurrentValueSubject<SessionSecurityState, Never>(.init(verificationState: .verified, recoveryState: .enabled)).asCurrentValuePublisher()
        
        liveLocationManager = LiveLocationManagerMock(.init())
    }
}

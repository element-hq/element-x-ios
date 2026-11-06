//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine

extension UserSessionManagerMock {
    struct Configuration {
        /// The live sessions, the first of which is active.
        var sessions: [UserSessionProtocol] = []
        var callbacksPublisher: AnyPublisher<UserSessionManagerCallback, Never> = Empty().eraseToAnyPublisher()
    }
    
    convenience init(_ configuration: Configuration) {
        self.init()
        
        userSessionForSessionDirectoriesPassphraseReturnValue = .success(UserSessionMock(.init()))
        clientSessionDelegate = KeychainControllerMock()
        activeSession = configuration.sessions.first
        sessionsPublisher = .init(configuration.sessions)
        callbacksPublisher = configuration.callbacksPublisher
    }
}

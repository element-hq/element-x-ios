//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine

extension UserSessionManagerMock {
    struct Configuration {
        var userSessions = CurrentValueSubject<[UserSessionProtocol], Never>([])
    }
    
    convenience init(_ configuration: Configuration) {
        self.init()
        
        let userSessions = configuration.userSessions
        userIDs = userSessions.value.map(\.clientProxy.userID)
        sessionsPublisher = userSessions.asCurrentValuePublisher()
        sessionForClosure = { userID in
            userSessions.value.first { $0.clientProxy.userID == userID }
        }
        
        userSessionForSessionDirectoriesPassphraseReturnValue = .success(UserSessionMock(.init()))
        clientSessionDelegate = KeychainControllerMock()
    }
}

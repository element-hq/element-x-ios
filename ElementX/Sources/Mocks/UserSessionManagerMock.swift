//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation

struct UserSessionManagerMockConfiguration {
    /// The live sessions, most recently active first.
    var userSessions: [UserSessionProtocol] = []
}

@MainActor extension UserSessionManagerMock {
    convenience init(_ configuration: UserSessionManagerMockConfiguration) {
        self.init()
        
        let userIDs = configuration.userSessions.map(\.clientProxy.userID)
        self.userIDs = userIDs
        userIDsPublisher = CurrentValueSubject<[String], Never>(userIDs).asCurrentValuePublisher()
        sessions = configuration.userSessions
        activeSession = configuration.userSessions.first
        sessionForClosure = { userID in
            configuration.userSessions.first { $0.clientProxy.userID == userID }
        }
    }
}

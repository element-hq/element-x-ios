//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

/// What a flow can know about a signed in account, without access to its session.
struct UserSessionDetails {
    let userID: String
}

extension UserSessionDetails {
    init(userSession: UserSessionProtocol) {
        userID = userSession.clientProxy.userID
    }
}

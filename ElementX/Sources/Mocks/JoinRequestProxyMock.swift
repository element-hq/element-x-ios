//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

struct JoinRequestProxyMockConfiguration {
    let eventID: String
    let userID: String
    var displayName: String?
    var avatarURL: URL?
    var timestamp: String?
    var reason: String?
    var isSeen = true
}

extension JoinRequestProxyMock {
    convenience init(_ configuration: JoinRequestProxyMockConfiguration) {
        self.init()
        eventID = configuration.eventID
        userID = configuration.userID
        displayName = configuration.displayName
        avatarURL = configuration.avatarURL
        reason = configuration.reason
        formattedTimestamp = configuration.timestamp
        isSeen = configuration.isSeen
    }
}

//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

struct KnockRequestProxyMockConfiguration {
    let eventID: String
    let userID: String
    var displayName: String?
    var avatarURL: URL?
    var timestamp: String?
    var reason: String?
    var isSeen = false
}

extension KnockRequestProxyMock {
    convenience init(_ configuration: KnockRequestProxyMockConfiguration) {
        self.init()
        eventID = configuration.eventID
        userID = configuration.userID
        displayName = configuration.displayName
        avatarURL = configuration.avatarURL
        reason = configuration.reason
        formattedTimestamp = configuration.timestamp
        isSeen = configuration.isSeen
        acceptReturnValue = .success(())
        declineReturnValue = .success(())
        banReturnValue = .success(())
        markAsSeenReturnValue = .success(())
    }
}

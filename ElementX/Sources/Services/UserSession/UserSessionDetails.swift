//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

/// What a flow can know about a signed in account, without access to its session.
struct UserSessionDetails {
    let userProfile: UserProfile
    /// The number of unread notifications, as counted for the app badge.
    let unreadCount: Int
    /// Loads media through the account's own homeserver, which may not federate with the others.
    let mediaProvider: MediaProviderProtocol
    
    var userID: String {
        userProfile.id
    }
}

extension UserSessionDetails {
    init(userSession: UserSessionProtocol) {
        userProfile = userSession.clientProxy.userProfilePublisher.value
        unreadCount = userSession.notificationService.badgeCountPublisher.value
        mediaProvider = userSession.mediaProvider
    }
}

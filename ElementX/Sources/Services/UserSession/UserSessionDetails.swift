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
    /// The details for an existing `UserSession` that's already live.
    init(userSession: UserSessionProtocol) {
        userProfile = userSession.clientProxy.userProfilePublisher.value
        unreadCount = userSession.notificationService.badgeCountPublisher.value
        mediaProvider = userSession.mediaProvider
    }
    
    /// The details for a `ClientProxy` that was remotely logged out by the server.
    ///
    /// **Note:** For this to work it requires the server to support MSC4262 so that the SDK has the user's global profile cached.
    init(remoteLogoutClientProxy clientProxy: ClientProxyProtocol) async {
        userProfile = clientProxy.userProfilePublisher.value
        unreadCount = 0
        mediaProvider = await RemoteLogoutAvatarMediaProvider(remoteLogoutClientProxy: clientProxy)
    }
}

extension UserSessionDetails: Equatable {
    nonisolated static func == (lhs: UserSessionDetails, rhs: UserSessionDetails) -> Bool {
        // Manual conformance as the media provider can't be compared.
        lhs.userProfile == rhs.userProfile && lhs.unreadCount == rhs.unreadCount
    }
}

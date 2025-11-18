//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import MatrixRustSDK

struct NSEUserSessionMockConfiguration {
    var inviteAvatarsVisibility = InviteAvatars.on
    var mediaPreviewVisibility = MediaPreviews.on
    var threadsEnabled = true
}

extension NSEUserSessionMock {
    convenience init(_ configuration: NSEUserSessionMockConfiguration) {
        self.init()
        
        underlyingInviteAvatarsVisibility = configuration.inviteAvatarsVisibility
        underlyingMediaPreviewVisibility = configuration.mediaPreviewVisibility
        underlyingThreadsEnabled = configuration.threadsEnabled
    }
}

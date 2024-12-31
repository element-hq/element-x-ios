//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import AnalyticsEvents

extension AnalyticsEvent.RoomModeration.Role {
    init(role: RoomMemberDetails.Role) {
        switch role {
        case .administrator:
            self = .Administrator
        case .moderator:
            self = .Moderator
        case .user:
            self = .User
        }
    }
}

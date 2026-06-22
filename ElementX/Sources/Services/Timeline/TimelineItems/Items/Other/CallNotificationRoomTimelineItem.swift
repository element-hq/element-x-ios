//
// Copyright 2025 Element Creations Ltd.
// Copyright 2024-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

nonisolated struct CallNotificationRoomTimelineItem: RoomTimelineItemProtocol, Equatable {
    let id: TimelineItemIdentifier
    let timestamp: Date
    let isDM: Bool
    let isVoiceCall: Bool
    
    /// Represents the state of the call notification - either tombstoned (ended) or active (ongoing)
    enum CallState: Equatable {
        /// A tombstoned/ended call notification
        case tombstoned(isDeclinedByMe: Bool, isDeclined: Bool)
        /// An active/ongoing call notification
        case active(activeMembers: [String],
                    isJoined: Bool,
                    callStartTimestamp: Date?)
    }
    
    let callState: CallState
    
    var properties = RoomTimelineItemProperties()
}

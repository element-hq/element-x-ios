//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import ElementCall

nonisolated extension ElementCallSystemEvent: @retroactive Equatable {
    public static func == (lhs: ElementCallSystemEvent, rhs: ElementCallSystemEvent) -> Bool {
        switch (lhs, rhs) {
        case (.audioSessionActivated, .audioSessionActivated), (.audioSessionDeactivated, .audioSessionDeactivated):
            true
        case let (.microphoneMuteChanged(lhsIsMuted), .microphoneMuteChanged(rhsIsMuted)):
            lhsIsMuted == rhsIsMuted
        case let (.endCallRequested(lhsRoomID), .endCallRequested(rhsRoomID)):
            lhsRoomID == rhsRoomID
        default:
            false
        }
    }
}

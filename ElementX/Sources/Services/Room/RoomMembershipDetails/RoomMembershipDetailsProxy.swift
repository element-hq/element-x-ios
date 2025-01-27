//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

struct RoomMembershipDetailsProxy: RoomMembershipDetailsProxyProtocol {
    let ownRoomMember: RoomMemberProxyProtocol
    let senderRoomMember: RoomMemberProxyProtocol?
}

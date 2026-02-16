//
// Copyright 2025 Element Creations Ltd.
// Copyright 2024-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

struct RoomDetails {
    let id: String
    let name: String?
    let avatar: RoomAvatar
    let canonicalAlias: String?
    let isEncrypted: Bool
    let isPublic: Bool
    let isDirect: Bool
    var historySharingState: RoomHistorySharingState?
}

//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

enum RoomListActivityVisibility: String, CaseIterable, Codable {
    /// Show unread badges for all unread messages (the default).
    case current
    /// Don't show badges but bold unread room names and their latest message
    case show
    /// Don't show badges and don't bold room names and messages
    case hide
}

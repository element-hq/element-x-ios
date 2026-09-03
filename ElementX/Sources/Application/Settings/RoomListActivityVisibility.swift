//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

nonisolated enum RoomListActivityVisibility: String, CaseIterable, Codable {
    /// Show unread badges and bold unread room names and their latest message (the default).
    case show
    /// Don't show badges and don't bold room names and messages
    case hide
}

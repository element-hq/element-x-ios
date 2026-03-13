//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

/// Enumeration of the two possible cases in which history sharing under MSC4268 is enabled. These
/// variants implicitly assume that the feature flag, `enableKeyShareOnInvite`, is set.
enum RoomHistorySharingState: Equatable {
    /// The feature flag is set, and the room history visibility is either `invited` or `joined`. New
    /// members of the room cannot read the room history.
    case hidden
    /// The feature flag is set, and the room history visibility is set to `shared`. New members of the
    /// room can read the room history.
    case shared
    /// The feature flag is set, and the room history visibility is set to `world_readable`. Anyone
    /// can read the room history.
    case worldReadable
}

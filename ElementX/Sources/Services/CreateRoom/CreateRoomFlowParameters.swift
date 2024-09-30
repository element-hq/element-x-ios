//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

/// This parameters are only used in the create room flow for having persisted informations between screens
struct CreateRoomFlowParameters {
    var name = ""
    var topic = ""
    var isRoomPrivate = true
    var avatarImageMedia: MediaInfo?
}

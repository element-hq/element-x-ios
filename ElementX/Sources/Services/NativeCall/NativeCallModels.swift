//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// What a call was started for; fixed at start time.
struct NativeCallData: Equatable {
    let roomID: String
    let roomDisplayName: String
    let isDirect: Bool
    let isAudioCall: Bool
    /// Whether this device is starting the call (rings the room) or joining one already running.
    let isStartingCall: Bool
}

enum NativeCallConnection: Equatable {
    case idle
    case joining
    case connectingMedia
    case connected
    case ended
    case failed(String)
}

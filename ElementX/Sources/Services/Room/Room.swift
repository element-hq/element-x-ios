//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import MatrixRustSDK

extension RoomProtocol {
    func joinCallIntent(voiceOnly: Bool) async -> Intent {
        switch await (hasActiveRoomCall(), isDirect()) {
        case (true, true): voiceOnly ? .joinExistingDmVoice : .joinExistingDm
        case (true, false): .joinExisting
        case (false, true): voiceOnly ? .startCallDmVoice : .startCallDm
        case (false, false): .startCall
        }
    }
}

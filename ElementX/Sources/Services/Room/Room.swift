//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import MatrixRustSDK

extension RoomProtocol {
    var joinCallIntent: Intent {
        get async {
            switch await (hasActiveRoomCall(), isDirect()) {
            case (true, true): .joinExistingDm
            case (true, false): .joinExisting
            case (false, true): .startCallDm
            case (false, false): .startCall
            }
        }
    }
}

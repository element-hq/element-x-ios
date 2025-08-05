//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import MatrixRustSDK

// sourcery: AutoMockable
protocol SpaceRoomListProxyProtocol { }

#warning("WIP, needs to be split into 2 files.")

class SpaceRoomListProxy: SpaceRoomListProxyProtocol {
    let spaceRoomList: SpaceServiceRoomListProtocol
    
    init(_ spaceRoomList: SpaceServiceRoomListProtocol) {
        self.spaceRoomList = spaceRoomList
    }
}
